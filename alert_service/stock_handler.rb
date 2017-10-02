require './common/common'
require_relative 'model/rule'
require_relative 'notification_service_client'

class StockHandler
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
    @notification_service_client = NotificationServiceClient.new(
      ENV['SA_NOTIFICATION_SERVICE_URL'],
      http_client
    )
    @metric_registry = registry.get(MetricRegistry.java_class)

    exec = registry.get(ExecController.java_class)
    exec.executor.schedule_at_fixed_rate(self, 0, 1, TimeUnit::SECONDS)
  end

  def handle(event)
    Promise.async do |d|
      Common::Log.debug event
      d.success(@buffer.offer(event, 1, TimeUnit::SECONDS))
    end
  end

  def run
    Execution.fork.start do |_|
      pending_stock_updates
        .defer(Duration.of_seconds(@backoff_duration))
        .then do |events|
          next if events.blank?
          find_matches(events)
            .flat_map { |notification| send_alert(notification) }
            .to_promise
            .on_error { |err| Common::Log.error "{error: #{err}}" }
            .then { |response| handle_response(response) }
        end
    end
  end

  def pending_stock_updates
    Promise
      .async { |downstream|
        events = []
        @buffer.drain_to(events, 1000)
        downstream.success(events)
      }
  end

  def find_matches(events)
    event_stream = Streams.publish(events)
    Streams.stream_map(event_stream) do |subscription, out|
      out.item_map(subscription) do |event|
        results = Rule.where('ticker = ? and (last_triggered is null or last_triggered < ?)',
                             event['ticker'], Time.now - 1.minute)
        matches = results.select do |rule|
          case rule.predicate
          when 'GT'
            event['price'].to_f > rule.value
          when 'LT'
            event['price'].to_f < rule.value
          when 'EQ'
            event['price'].to_f == rule.value
          else
            false
          end
        end

        matches.each do |rule|
          rule.update(last_triggered: Time.now)
          out.item(
            {
              id: rule.id,
              ticker: event['ticker'],
              price: event['price'],
              phone: rule.phone
            }
          )
        end
      end
    end
  end

  def send_alert(notification)
    @notification_service_client
      .send_notification(notification)
      .on_error do |err|
        reset_trigger(notification[:id]).then {}
        backpressure(true)
        Common::Log.error "{event: #{notification}, error: #{err}}"
      end
  end

  def handle_response(response)
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

  def reset_trigger(id)
    Promise.async do |d|
      Common::Log.debug "resetting trigger for id=#{id}"
      rule = Rule.find(id)
      rule.update(last_triggered: nil)
      d.success(true)
    end
  end
end