require 'bundler/setup'
Bundler.require
require 'java'
require 'json'
require './weather_service_client'
require './yahoo_weather_client'

java_import 'ratpack.server.RatpackServer'
java_import 'java.time.Duration'
java_import 'ratpack.stream.Streams'
java_import 'ratpack.http.ResponseChunks'
java_import 'ratpack.http.client.HttpClient'
java_import 'ratpack.exec.Promise'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.handlers do |chain|
    chain.get do |ctx|
      http_client = ctx.get(HttpClient.java_class)
      weather_service_client = WeatherServiceClient.new(ENV['WA_WEATHER_SERVICE_URL'], http_client)

      locations = %w(94105 94103 94102 94025 94040 95054)
      http_client = ctx.get(HttpClient.java_class)
      source_weather_events(locations, http_client)
      .toList
      .then do |events|
        ctx.render(
          ResponseChunks.string_chunks(
            stream_weather_events(events)
              .flat_map { |event| weather_service_client.send_weather_event(event) }
              .map { |response|
                puts "#{Time.now}: #{response.status.code}"
                response.status.code.to_s
              }
          )
        )
      end
    end
  end
end

def stream_weather_events(events)
  Streams.constant(1)
  .map { |_|
    event = events[Random.rand(events.length - 1)]
    puts event
    event
  }
end

def source_weather_events(locations, http_client)
  weather_source = YahooWeatherClient.new(ENV['WA_API_KEY'], http_client)
  Streams.publish(locations)
    .flat_map { |location|
      weather_source.current_conditions(location)
        .left(Promise.value(location))
    }
    .map { |pair|
      response = pair.right
      pair.right(JSON.parse(response.body.text))
    }
    .map { |pair|
      {
        location: pair.left,
        temperature: pair.right.dig('query', 'results', 'channel', 'item', 'condition', 'temp')
      }
    }
end