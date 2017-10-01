require './common/common'
require './common/metrics_reporter'
require_relative 'notification_handler'

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
      b.add(NotificationHandler.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('notification') do |ctx|
      handler = ctx.get(NotificationHandler.java_class)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| handler.handle(event) }
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