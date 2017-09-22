require 'jbundler'
require 'java'
require './common/metrics_reporter'
require './weather_service/alarm_service_client'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.http.client.HttpClient'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsModule'
java_import 'ratpack.dropwizard.metrics.MetricsWebsocketBroadcastHandler'
java_import 'ratpack.guice.Guice'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.registry(
    Guice::registry do |b|
      b.module(DropwizardMetricsModule.new) do |m|
        m.web_socket
      end

      b.add(MetricsReporter.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.get("admin/metrics", MetricsWebsocketBroadcastHandler.new)

    chain.post('weather') do |ctx|
      http_client = ctx.get(HttpClient.java_class)
      alarm_service_client = AlarmServiceClient.new(ENV['WA_ALARM_SERVICE_URL'], http_client)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| alarm_service_client.send_event(event) }
        .then { ctx.render('OK') }
    end
  end
end