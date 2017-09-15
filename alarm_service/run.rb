require 'jbundler'
require 'java'
require 'jruby/core_ext'
require 'json'

java_import 'ratpack.server.RatpackServer'
java_import 'ratpack.dropwizard.metrics.DropwizardMetricsModule'
java_import 'ratpack.guice.Guice'
java_import 'java.nio.file.FileSystems'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('WA_')
    cfg.base_dir(FileSystems.default.get_path(File.absolute_path('.')))
  end

  server.registry(
    Guice::registry do |r|
      r.module(DropwizardMetricsModule.new) do |m|
        m.jmx
      end
    end
  )

  server.handlers do |chain|
    chain.files do |f|
      f.dir('public').index_files('index.html')
    end

    chain.post('weather') do |ctx|
      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .map { |event| puts event}
        .map { |event|
          sleep(2)
        }
        .then { ctx.render('OK') }
    end

    chain.post('alarm') do |ctx|
      ctx.response.status(501).send('Unimplemented')
    end
  end
end