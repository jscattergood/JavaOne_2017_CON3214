require 'jbundler'
require 'java/override'
require 'logger'

java_import 'com.codahale.metrics.MetricRegistry'
java_import 'com.codahale.metrics.MetricFilter'
java_import 'com.codahale.metrics.graphite.Graphite'
java_import 'io.netty.buffer.ByteBufAllocator'
java_import 'java.lang.Runnable'
java_import 'java.nio.charset.Charset'
java_import 'java.nio.file.FileSystems'
java_import 'java.util.concurrent.ConcurrentHashMap'
java_import 'java.util.concurrent.TimeUnit'
java_import 'java.util.concurrent.LinkedBlockingDeque'
java_import 'java.time.Duration'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsModule'
java_import 'ratpack.dropwizard.metrics.internal.MetricRegistryJsonMapper'
java_import 'ratpack.exec.ExecController'
java_import 'ratpack.exec.Execution'
java_import 'ratpack.exec.Operation'
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

  class Log
    def self.debug(message)
      @logger ||= create_logger
      @logger.debug(message)
    end

    def self.info(message)
      @logger ||= create_logger
      @logger.info(message)
    end

    def self.warn(message)
      @logger ||= create_logger
      @logger.warn(message)
    end

    def self.error(message)
      @logger ||= create_logger
      @logger.error(message)
    end

    def self.create_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      logger
    end
  end
end
