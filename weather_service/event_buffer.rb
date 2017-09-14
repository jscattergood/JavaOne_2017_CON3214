require 'java'

java_import 'java.lang.Runnable'
java_import 'java.util.concurrent.TimeUnit'
java_import 'java.util.concurrent.LinkedBlockingDeque'
java_import 'ratpack.stream.Streams'
java_import 'ratpack.service.Service'
java_import 'ratpack.exec.ExecController'
java_import 'ratpack.exec.Execution'
java_import 'ratpack.exec.Promise'

class EventBuffer
  include Service
  include Runnable

  def initialize
    @buffer = LinkedBlockingDeque.new(100)
  end

  def add(event)
    Promise.async do |d|
      d.success(@buffer.offer(event, 1, TimeUnit::SECONDS))
    end
  end

  def onStart(start_event)
    registry = start_event.registry
    http_client = registry.get(HttpClient.java_class)
    @alarm_service_client = AlarmServiceClient.new(ENV['WA_ALARM_SERVICE_URL'], http_client)

    exec = registry.get(ExecController.java_class)
    exec.executor.schedule_at_fixed_rate(self, 0, 1, TimeUnit::SECONDS)
  end

  def run
    Execution.fork.start do |_|
      get_events
        .map { |events| reduce_events(events) }
        .flat_map { |events| send_events(events) }
        .then { |responses| puts "#{Time.now}: #{responses.length} responses" }
    end
  end

  def get_events
    #TODO Make this a custom publisher
    Promise
      .async { |d|
        events = []
        @buffer.drain_to(events, 10)
        d.success(events)
      }
  end

  def send_events(events)
    Streams
      .publish(events)
      .flat_map do |event|
        @alarm_service_client
          .send_weather_event(event)
          .on_error do |err|
            @buffer.offer(event, 1, TimeUnit::SECONDS)
            STDERR.puts "{event: #{event}, error: #{err}}"
          end
      end
      .to_list
  end

  def reduce_events(events)
    event_hash = {}
    events.each { |event| event_hash[event['location']] = event['temperature'] }
    events = []
    event_hash.each_pair { |l, t| events << { location: l, temperature: t } }
    events
  end
end