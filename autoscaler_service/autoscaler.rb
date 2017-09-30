require './common/common'
require_relative 'orbiter_service_client'

class AutoScaler
  include Java::Override
  include Service

  def on_start(start_event)
    registry = start_event.registry
    http_client = registry.get(HttpClient.java_class)
    @orbiter_client = OrbiterServiceClient.new(ENV['SA_ORBITER_SERVICE_URL'], http_client)
  end

  def handle_event(ip, event)
    puts "#{ip} #{event}"
    meters = event.dig('metrics', 'meters')
    check_backpressure(meters)
  end

  def check_backpressure(meters)
    bp = meters.select { |k, _| k.start_with? 'backpressure.service' }
    Streams.publish(bp.to_a)
      .flat_map { |array| adjust_scale(array.first, array.last) }
      .to_list
  end

  def adjust_scale(metric_name, metric_value)
    service = metric_name.split('.').last
    Promise
      .value(metric_value)
      .next_op_if(
        ->(v) { v['m1_rate'] < 0.01 && v['m5_rate'] < 0.01 },
        ->(_) { scale_down(service) }
      )
      .next_op_if(
        ->(v) { v['m1_rate'] > 1 },
        ->(_) { scale_up(service) }
      )
  end

  def scale_up(service)
    Operation.of {
      @orbiter_client.scale_up(service)
        .then { |response| puts response.body.text if response.status.code >= 400 }
    }
  end

  def scale_down(service)
    Operation.of {
      @orbiter_client.scale_down(service)
        .then { |response| puts response.body.text if response.status.code >= 400 }
    }
  end
end