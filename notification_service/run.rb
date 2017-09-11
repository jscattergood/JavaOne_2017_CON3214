require 'jbundler'
require 'java'

java_import 'ratpack.server.RatpackServer'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('notification') do |ctx|

    end
  end
end