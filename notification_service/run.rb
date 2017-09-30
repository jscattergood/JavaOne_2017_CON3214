require './common/common'
require './common/metrics_reporter'
require_relative 'twilio_service_client'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('SA_')
  end

  server.registry(
    Guice.registry do |b|
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

    chain.post('notification') do |ctx|
      http_client = ctx.get(HttpClient.java_class)

      client = TwilioServiceClient.new(http_client)
      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |n| client.send_notification(n) }
        .then { |response| ctx.render(response.body.text) }
    end
  end
end