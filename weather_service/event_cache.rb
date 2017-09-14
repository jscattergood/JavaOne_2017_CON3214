require 'java'

java_import 'java.lang.Runnable'
java_import 'java.util.concurrent.TimeUnit'
java_import 'java.util.concurrent.ConcurrentHashMap'
java_import 'ratpack.stream.Streams'
java_import 'ratpack.service.Service'
java_import 'ratpack.exec.ExecController'
java_import 'ratpack.exec.Execution'
java_import 'ratpack.exec.Promise'

class EventCache
  include Service
  include Runnable

  def initialize
    @cache = ConcurrentHashMap.new(100000)
    @updates = ConcurrentHashMap.new
  end

  def add(event)
    Promise.async do |d|
      @cache.put(event['location'], event['temperature'])
      @updates.put(event['location'], true)
      d.success(true)
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
        .map { |keys| hydrate_events(keys) }
        .flat_map { |events| send_events(events) }
        .then { |responses| puts "#{Time.now}: #{responses.length} responses" }
    end
  end

  def get_events
    #TODO Make this a custom publisher
    Promise
      .async { |d|
        keys = []
        count = 0
        @updates.each_key do |key|
          break if count >= 10
          count += 1
          keys << key
          @updates.remove(key)
        end
        d.success(keys)
      }
  end

  def send_events(events)
    Streams
      .publish(events)
      .flat_map do |event|
        @alarm_service_client
          .send_weather_event(event)
          .on_error do |err|
            @updates.put(event[:location], true)
            STDERR.puts "{event: #{event}, error: #{err}}"
          end
      end
      .to_list
  end

  def hydrate_events(keys)
    keys.map do |key|
      { location: key, temperature: @cache[key] }
    end
  end
end