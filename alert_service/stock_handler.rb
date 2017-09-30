require './common/common'
require_relative 'model/alert'
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
      d.success(@buffer.offer(event, 1, TimeUnit::SECONDS))
    end
  end

  def run
    Execution.fork.start do |_|
      get_events
        .defer(Duration.of_seconds(@backoff_duration))
        .then do |events|
          next if events.blank?
          find_matches(events)
            .flat_map { |notification| send_message(notification) }
            .to_promise.then { |response| handle_response(response) }
        end
    end
  end

  def get_events
    Promise
      .async { |downstream|
        events = []
        @buffer.drain_to(events, 10)
        downstream.success(events)
      }
  end

  def find_matches(events)
    event_stream = Streams.publish(events)
    Streams.stream_map(event_stream) do |subscription, out|
      out.item_map(subscription) do |event|
        results = Alert.where('ticker = ? and last_triggered is null or last_triggered < ?',
                              event['ticker'], Time.now - 1.minute)
        matches = results.select do |a|
          case a.predicate
          when 'GT'
            event['price'].to_f > a.value
          when 'LT'
            event['price'].to_f < a.value
          when 'EQ'
            event['price'].to_f == a.value
          else
            false
          end
        end

        matches.each do |alert|
          alert.update(last_triggered: Time.now)
          out.item(
            {
              id: alert.id,
              ticker: event['ticker'],
              price: event['price'],
              phone: alert.phone
            }
          )
        end
      end
    end
  end

  def send_message(notification)
    @notification_service_client
      .send_notification(notification)
      .on_error do |err|
        reset_trigger(notification[:id]).then {}
        backpressure(true)
        STDERR.puts "{event: #{notification}, error: #{err}}"
      end
  end

  def handle_response(response)
    return if response.nil?
    puts "#{Time.now}: #{response.status.code}"
    backpressure(response.status.code == 429 || response.status.code >= 500)
  end

  def backpressure(backoff)
    if backoff
      @metric_registry.meter('backpressure.service.notification').mark
      @backoff_duration = [30, 1 + @backoff_duration * 2].min
      puts "increasing back off to #{@backoff_duration} secs"
    else
      @backoff_duration = [@backoff_duration / 2, 1].max
      if @backoff_duration > 1
        puts "decreasing back off to #{@backoff_duration} secs"
      else
        @backoff_duration = 0
      end
    end
  end

  def reset_trigger(id)
    Promise.async do |d|
      puts "resetting trigger for id=#{id}"
      alert = Alert.find(id)
      alert.update(last_triggered: nil)
      d.success(true)
    end
  end
end