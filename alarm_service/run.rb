require 'bundler/setup'
Bundler.require
require 'java'
require 'jruby/core_ext'
require 'json'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.stream.Streams'
java_import 'ratpack.http.ResponseChunks'
java_import 'java.time.Duration'
java_import 'java.util.HashMap'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('weather') do |ctx|
      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .map { |event| puts event}
        .then { ctx.render('OK') }
    end

    chain.post('alarm') do |ctx|
      ctx.response.status(501).send('Unimplemented')
    end
  end
end