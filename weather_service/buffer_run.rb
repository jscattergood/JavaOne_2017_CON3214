require './common/common'
require './common/metrics_reporter'
require './weather_service/alarm_service_client'
require './weather_service/event_buffer'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.registry(
    Guice::registry do |b|
      b.module(DropwizardMetricsModule.new) do |m|
        m.jmx
      end

      b.add(MetricsReporter.new)
      b.add(EventBuffer.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.get("admin/metrics", MetricsWebsocketBroadcastHandler.new)

    chain.post('weather') do |ctx|
      buffer = ctx.get(EventBuffer.java_class)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| buffer.add(event) }
        .then { |buffered|
          if buffered
            ctx.render('OK')
          else
            puts "backpressure!!!"
            ctx.response.status(429).send
          end
        }
    end
  end
end