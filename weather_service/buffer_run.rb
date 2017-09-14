require 'jbundler'
require 'java'
require './weather_service/alarm_service_client'
require './weather_service/event_buffer'

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

      r.add(EventBuffer.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

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