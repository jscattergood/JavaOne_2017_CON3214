require 'jbundler'
require 'java'
require './weather_service_backpressure/alarm_service_client'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.http.client.HttpClient'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('weather') do |ctx|
      http_client = ctx.get(HttpClient.java_class)
      alarm_service_client = AlarmServiceClient.new(ENV['WA_ALARM_SERVICE_URL'], http_client)

      ctx.request.body
        .map { |b|
          puts b.text
          JSON.parse(b.text)
        }
        .flat_map { |event| alarm_service_client.send_weather_event(event) }
        .then { ctx.render('OK') }
    end
  end
end