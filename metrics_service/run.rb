require 'jbundler'
require 'java'
require './common/metrics_reporter'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsModule'
java_import 'ratpack.guice.Guice'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
  end

  server.registry(
    Guice::registry do |b|
      b.module(DropwizardMetricsModule.new) do |m|
        m.web_socket
      end

      b.add(MetricsReporter.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('metrics') do |ctx|
      ip = ctx.request.get_remote_address
      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .map { |event| puts "#{ip} #{event}"}
        .then { ctx.render('OK') }
    end
  end
end