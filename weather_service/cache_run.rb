require './common/common'
require './common/metrics_reporter'
require './weather_service/alarm_service_client'
require './weather_service/event_cache'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.registry(
    Guice::registry do |b|
      b.module(DropwizardMetricsModule.new) do |m|
        m.jmx
        m.graphite do |g|
          g.reporter_interval(Duration.of_seconds(10))
          g.prefix("service.#{ENV['WA_SERVICE_NAME']}")
          g.sender(Graphite.new(ENV['WA_GRAPHITE_HOST'], 2003))
        end
      end

      b.add(MetricsReporter.new)
      b.add(EventCache.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('weather') do |ctx|
      cache = ctx.get(EventCache.java_class)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| cache.add(event) }
        .then do |cached|
          if cached
            ctx.render('OK')
          else
            puts "backpressure!!!"
            ctx.response.status(429).send
          end
        end
    end
  end
end