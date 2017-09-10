require 'bundler/setup'
Bundler.require
require 'java'
require 'json'
require './weather_service_client'
require './yahoo_weather_client'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.stream.Streams'
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

      stream_weather_events(http_client)
        .flat_map { |event|
          weather_service_client.send_weather_event(event)
        }
        .toList
        .then {
          ctx.render('OK')
        }
    end
  end
end

def stream_weather_events(http_client)
  weather_source = YahooWeatherClient.new(ENV['WA_API_KEY'], http_client)
  locations = %w(94105 94103 94102 94025 94040 95054)
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