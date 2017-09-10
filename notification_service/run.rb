require 'bundler/setup'
Bundler.require
require 'java'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.stream.Streams'
java_import 'ratpack.http.ResponseChunks'
java_import 'java.time.Duration'

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