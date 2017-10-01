require './common/common'
require './common/metrics_reporter'
require_relative 'alert_service_client'
require_relative 'event_buffer'

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
      b.add(EventBuffer.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('stock') do |ctx|
      buffer = ctx.get(EventBuffer.java_class)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| buffer.add(event) }
        .then do |buffered|
          if buffered
            ctx.render('OK')
          else
            Common::Log.debug 'backpressure!!!'
            ctx.response.status(429).send
          end
        end
    end
  end
end