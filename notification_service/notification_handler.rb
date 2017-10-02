require './common/common'
require_relative 'alert_service_client'
require_relative 'twilio_service_client'

class NotificationHandler
  include Java::Override
  include Service
  include Runnable

  def initialize
    @backoff_duration = 0
    @buffer = LinkedBlockingDeque.new(1000)
  end

  def on_start(start_event)
    registry = start_event.registry

    http_client = registry.get(HttpClient.java_class)
    @twilio_service_client = TwilioServiceClient.new(http_client)
    @alert_service_client = AlertServiceClient.new(ENV['SA_ALERT_SERVICE_URL'],http_client)

    @metric_registry = registry.get(MetricRegistry.java_class)

    exec = registry.get(ExecController.java_class)
    exec.executor.schedule_at_fixed_rate(self, 0, 1, TimeUnit::SECONDS)
  end

  def handle(notification)
    Promise.async do |d|
      Common::Log.debug notification
      d.success(@buffer.offer(notification, 1, TimeUnit::SECONDS))
    end
  end

  def run
    Execution.fork.start do |_|
      pending_notifications
        .flat_map { |notification| send_notifications(notification) }
        .defer(Duration.of_seconds(@backoff_duration))
        .then { |responses| responses.each { |response| check_backpressure(response) } }
    end
  end

  def pending_notifications
    Promise
      .async { |downstream|
        events = []
        @buffer.drain_to(events, 1000)
        downstream.success(events)
      }
  end

  def send_notifications(notifications)
    Streams
      .publish(notifications)
      .flat_map do |event|
        @twilio_service_client
          .send_notification(event)
          .on_error { |err| handle_error(err, event) }
          .flat_map { |response| handle_response(event, response) }
      end
      .to_list
  end

  def handle_response(event, response)
    if response.status.code < 500
      send_success(event['id'])
    else
      Promise.value(response)
    end
  end

  def handle_error(err, event)
    @buffer.offer(event, 1, TimeUnit::SECONDS)
    backpressure(true)
    send_failure(event['id']).then {}
    Common::Log.error "{event: #{event}, error: #{err}}"
  end

  def check_backpressure(response)
    return if response.nil?
    Common::Log.debug "#{response.status.code}"
    backpressure(response.status.code == 429 || response.status.code >= 500)
  end

  def backpressure(backoff)
    if backoff
      @metric_registry.meter('backpressure.service.notification').mark
      @backoff_duration = [30, 1 + @backoff_duration * 2].min
      Common::Log.info "increasing back off to #{@backoff_duration} secs"
    else
      @backoff_duration = [@backoff_duration / 2, 1].max
      if @backoff_duration > 1
        Common::Log.info "decreasing back off to #{@backoff_duration} secs"
      else
        @backoff_duration = 0
      end
    end
  end

  def send_failure(id)
    Common::Log.debug "send failure for #{id}"
    @alert_service_client.send_failure(id)
  end

  def send_success(id)
    Common::Log.debug "send success for #{id}"
    @alert_service_client.send_success(id)
  end
end