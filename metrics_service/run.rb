require './common/common'
require './common/metrics_reporter'
require './metrics_service/autoscaler_service_client'

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
    end
  )

  server.handlers do |chain|
    chain.get do |ctx|
      ctx.render('OK')
    end

    chain.post('metrics') do |ctx|
      ip = ctx.request.get_remote_address
      http = ctx.get(HttpClient.java_class)
      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .flat_map { |event| handle_event(http, event, ip) }
        .then { ctx.render('OK') }
    end
  end

  def handle_event(http, event, ip)
    puts "#{ip} #{event}"
    client = AutoscalerServiceClient.new(ENV['WA_AUTOSCALER_SERVICE_URL'], http)
    meters = event.dig('metrics', 'meters')
    bp = meters.select { |k,_| k.start_with? 'service.backpressure' }
    Streams.publish(bp.to_a)
    .filter { |entry| entry.last['m1_rate'] > 0.10 }
    .flat_map do |entry|
      service = entry.first.split('.').last
      client.scale_up(service)
    end
    .to_list
  end
end