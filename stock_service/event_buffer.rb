require './common/common'

class EventBuffer
  include Java::Override
  include Service
  include Runnable

  def initialize
    @buffer = LinkedBlockingDeque.new(100)
    @backoff_duration = 0
  end

  def add(event)
    Promise.async do |d|
      d.success(@buffer.offer(event, 1, TimeUnit::SECONDS))
    end
  end

  def on_start(start_event)
    registry = start_event.registry
    http_client = registry.get(HttpClient.java_class)
    @alert_service_client = AlertServiceClient.new(ENV['SA_ALERT_SERVICE_URL'], http_client)
    @metric_registry = registry.get(MetricRegistry.java_class)

    exec = registry.get(ExecController.java_class)
    exec.executor.schedule_at_fixed_rate(self, 0, 1, TimeUnit::SECONDS)
  end

  def run
    Execution.fork.start do |_|
      get_events
        .map { |events| reduce_events(events) }
        .flat_map { |events| send_events(events) }
        .defer(Duration.of_seconds(@backoff_duration))
        .then do |responses|
          responses.each { |response| handle_response(response) }
        end
    end
  end

  def handle_response(response)
    Common::Log.debug "#{response.status.code}"
    backpressure(response.status.code == 429 || response.status.code >= 500)
  end

  def backpressure(backoff)
    if backoff
      @metric_registry.meter('backpressure.service.alert').mark
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

  def get_events
    #TODO Make this a custom publisher
    Promise
      .async { |downstream|
        events = []
        @buffer.drain_to(events, 10)
        downstream.success(events)
      }
  end

  def send_events(events)
    Streams
      .publish(events)
      .flat_map do |event|
        @alert_service_client
          .send_event(event)
          .on_error do |err|
            @buffer.offer(event, 1, TimeUnit::SECONDS)
            backpressure(true)
            Common::Log.error "{event: #{event}, error: #{err}}"
          end
      end
      .to_list
  end

  def reduce_events(events)
    #TODO average the price by ticker
    event_hash = {}
    events.each { |event| event_hash[event['ticker']] = event['price'] }
    events = []
    event_hash.each_pair do |l, t|
      events << { ticker: l, price: t } unless l.nil?
    end
    events
  end
end