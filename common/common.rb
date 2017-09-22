require 'jbundler'
require 'java/override'

java_import 'com.codahale.metrics.MetricRegistry'
java_import 'com.codahale.metrics.MetricFilter'
java_import 'io.netty.buffer.ByteBufAllocator'
java_import 'java.lang.Runnable'
java_import 'java.nio.charset.Charset'
java_import 'java.util.concurrent.ConcurrentHashMap'
java_import 'java.util.concurrent.TimeUnit'
java_import 'java.util.concurrent.LinkedBlockingDeque'
java_import 'java.time.Duration'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsModule'
java_import 'ratpack.dropwizard.metrics.internal.MetricRegistryJsonMapper'
java_import 'ratpack.exec.ExecController'
java_import 'ratpack.exec.Execution'
java_import 'ratpack.exec.Promise'
java_import 'ratpack.guice.Guice'
java_import 'ratpack.http.ResponseChunks'
java_import 'ratpack.http.client.HttpClient'
java_import 'ratpack.service.Service'
java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.stream.Streams'

module Common
  def to_uri(url)
    java.net.URI.new(url)
  end
end