require './common/common'
require './common/autoscaler_service_client'

class MetricsReporter
  include Java::Override
  include Service
  include Runnable

  def on_start(start_event)
    registry = start_event.registry

    http_client = registry.get(HttpClient.java_class)
    @autoscaler_client = AutoscalerServiceClient.new(ENV['SA_AUTOSCALER_SERVICE_URL'], http_client)

    @byte_buf_allocator = registry.get(ByteBufAllocator.java_class)
    @metric_registry = registry.get(MetricRegistry.java_class)

    exec = registry.get(ExecController.java_class)
    exec.executor.schedule_at_fixed_rate(self, 0, 15, TimeUnit::SECONDS)
  end

  def run
    Execution.fork.start do |_|
      Promise
        .value(@metric_registry)
        .map(MetricRegistryJsonMapper.new(@byte_buf_allocator, MetricFilter::ALL))
        .map { |byte_buf| byte_buf.to_string(Charset.default_charset) }
        .map { |string| JSON.parse(string) }
        .flat_map { |metric| send_event(metric) }
        .then { |__| }
    end
  end

  def send_event(metric)
    @autoscaler_client
      .send_event(metric)
      .on_error { |err| Common::Log.error "{metric: #{metric}, error: #{err}}" }
  end
end