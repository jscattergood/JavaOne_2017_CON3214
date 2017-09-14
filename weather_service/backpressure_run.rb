require 'jbundler'
require 'java'
require './weather_service/alarm_service_client'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.http.client.HttpClient'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsModule'
java_import 'ratpack.guice.Guice'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.registry(
    Guice::registry do |r|
      r.module(DropwizardMetricsModule.new) do |m|
        m.jmx
      end
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('weather') do |ctx|
      http_client = ctx.get(HttpClient.java_class)
      alarm_service_client = AlarmServiceClient.new(ENV['WA_ALARM_SERVICE_URL'], http_client)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| alarm_service_client.send_weather_event(event) }
        .then { ctx.render('OK') }
    end
  end
end