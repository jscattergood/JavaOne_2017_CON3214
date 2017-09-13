require 'jbundler'
require 'java'
require './weather_service/alarm_service_client'
require './weather_service/event_cache'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.http.client.HttpClient'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.registry_of do |r|
    r.add(EventCache.new)
  end

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('weather') do |ctx|
      cache = ctx.get(EventCache.java_class)

      ctx.request.body
        .map { |b|
          JSON.parse(b.text)
        }
        .flat_map { |event| cache.add(event) }
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