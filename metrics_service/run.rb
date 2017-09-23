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
        .flat_map { |event| handle_event(http, ip, event) }
        .then { ctx.render('OK') }
    end
  end

  def handle_event(http, ip, event)
    puts "#{ip} #{event}"
    client = AutoscalerServiceClient.new(ENV['WA_AUTOSCALER_SERVICE_URL'], http)
    meters = event.dig('metrics', 'meters')
    check_backpressure(client, meters)
  end

  def check_backpressure(client, meters)
    bp = meters.select { |k, _| k.start_with? 'service.backpressure' }
    Streams.publish(bp.to_a)
      .flat_map do |entry|
      adjust_scale(client, entry)
    end
      .to_list
  end

  def adjust_scale(client, entry)
    Promise
      .value(entry)
      .next_op_if(
        ->(e) { e.last['m1_rate'] < 0.01 && e.last['m5_rate'] < 0.01 },
        lambda do |e|
          service = e.first.split('.').last
          Operation.of {
            client.scale_down(service)
              .then do |response|
                puts response.body.text if response.status.code >= 400
              end
          }
        end
      )
      .next_op_if(
        ->(e) { e.last['m1_rate'] > 0.10 },
        lambda do |e|
          service = e.first.split('.').last
          Operation.of {
            client.scale_up(service)
              .then do |response|
                puts response.body.text if response.status.code >= 400
              end
          }
        end
      )
  end
end