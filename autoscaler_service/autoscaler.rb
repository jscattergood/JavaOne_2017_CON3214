require './common/common'
require './autoscaler_service/orbiter_service_client'

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
      .flat_map do |entry|
      adjust_scale(entry)
    end
      .to_list
  end

  def adjust_scale(entry)
    Promise
      .value(entry)
      .next_op_if(
        ->(e) { e.last['m1_rate'] < 0.01 && e.last['m5_rate'] < 0.01 },
        lambda do |e|
          service = e.first.split('.').last
          Operation.of {
            @orbiter_client.scale_down(service)
              .then do |response|
              puts response.body.text if response.status.code >= 400
            end
          }
        end
      )
      .next_op_if(
        ->(e) { e.last['m1_rate'] > 1 },
        lambda do |e|
          service = e.first.split('.').last
          Operation.of {
            @orbiter_client.scale_up(service)
              .then do |response|
              puts response.body.text if response.status.code >= 400
            end
          }
        end
      )
  end
end