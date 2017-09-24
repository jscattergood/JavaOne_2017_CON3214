require './common/common'
require './common/metrics_reporter'
require './monitor_service/autoscaler'

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
      b.add(AutoScaler.new)
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('metrics') do |ctx|
      scaler = ctx.get(AutoScaler.java_class)

      ip = ctx.request.get_remote_address
      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| scaler.handle_event(ip, event) }
        .then { ctx.render('OK') }
    end
  end
end