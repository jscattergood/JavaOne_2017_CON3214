require './common/common'
require './common/metrics_reporter'
require './stock_service/alert_service_client'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('SA_')
  end

  server.registry(
    Guice::registry do |b|
      b.module(DropwizardMetricsModule.new) do |m|
        m.jmx
        m.graphite do |g|
          g.reporter_interval(Duration.of_seconds(10))
          g.prefix("service.#{ENV['SA_SERVICE_NAME']}")
          g.sender(Graphite.new(ENV['SA_GRAPHITE_HOST'], 2003))
        end
      end

      b.add(MetricsReporter.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.get("admin/metrics", MetricsWebsocketBroadcastHandler.new)

    chain.post('stock') do |ctx|
      http_client = ctx.get(HttpClient.java_class)
      alert_service_client = AlertServiceClient.new(ENV['SA_ALERT_SERVICE_URL'], http_client)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| alert_service_client.send_event(event) }
        .then { ctx.render('OK') }
    end
  end
end