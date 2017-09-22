require 'java/override'
require './common/metrics_service_client'

java_import 'com.codahale.metrics.MetricRegistry'
java_import 'com.codahale.metrics.MetricFilter'
java_import 'java.lang.Runnable'
java_import 'java.nio.charset.Charset'
java_import 'java.util.concurrent.TimeUnit'
java_import 'io.netty.buffer.ByteBufAllocator'
java_import 'ratpack.dropwizard.metrics.internal.MetricRegistryJsonMapper'
java_import 'ratpack.exec.ExecController'
java_import 'ratpack.exec.Execution'
java_import 'ratpack.exec.Promise'
java_import 'ratpack.http.client.HttpClient'
java_import 'ratpack.service.Service'

class MetricsReporter
  include Java::Override
  include Service
  include Runnable

  def on_start(start_event)
    registry = start_event.registry

    http_client = registry.get(HttpClient.java_class)
    @metrics_service_client = MetricsServiceClient.new(ENV['WA_METRICS_SERVICE_URL'], http_client)

    @byte_buf_allocator = registry.get(ByteBufAllocator.java_class)
    @metrics_registry = registry.get(MetricRegistry.java_class)

    exec = registry.get(ExecController.java_class)
    exec.executor.schedule_at_fixed_rate(self, 0, 15, TimeUnit::SECONDS)
  end

  def run
    Execution.fork.start do |_|
      Promise.value(@metrics_registry)
        .map(MetricRegistryJsonMapper.new(@byte_buf_allocator, MetricFilter::ALL))
        .map { |byte_buf| byte_buf.to_string(Charset.default_charset) }
        .map { |string|
          JSON.parse(string)
        }
        .flat_map { |metric|
          @metrics_service_client.send_event(metric)
            .on_error do |err|
            STDERR.puts "{metric: #{metric}, error: #{err}}"
          end
        }
        .then { |__| }
    end
  end
end