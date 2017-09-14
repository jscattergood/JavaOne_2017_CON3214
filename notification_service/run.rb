require 'jbundler'
require 'java'

java_import 'ratpack.server.RatpackServer'
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
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('notification') do |ctx|

    end
  end
end