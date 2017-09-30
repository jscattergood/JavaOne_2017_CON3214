require 'active_record'
require 'activerecord-jdbc-adapter'
require './common/common'
require './common/metrics_reporter'
require_relative 'db/startup'
require_relative 'stock_handler'

RatpackServer.start do |server|
  server.server_config do |cfg|
    cfg.env('SA_')
    cfg.base_dir(FileSystems.default.get_path(File.absolute_path('.')))
  end

  server.registry(
    Guice.registry do |b|
      b.module(DropwizardMetricsModule.new) do |m|
        m.jmx
        m.graphite do |g|
          g.reporter_interval(Duration.of_seconds(10))
          g.prefix("service.#{ENV['SA_SERVICE_NAME']}")
          g.sender(Graphite.new(ENV['SA_GRAPHITE_HOST'], 2003))
        end
      end

      b.add(MetricsReporter.new)
      b.add(StockHandler.new)
    end
  )

  server.handlers do |chain|
    chain.files do |f|
      f.dir('public').index_files('index.html')
    end

    chain.post('stock') do |ctx|
      handler = ctx.get(StockHandler.java_class)

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .map { |event| puts event; event}
        .flat_map { |event| handler.handle(event) }
        .then { ctx.render('OK') }
    end

    chain.post('alert') do |ctx|
      ctx.response.status(501).send('Unimplemented')
    end

    chain.patch('alert') do |ctx|
      ctx.response.status(501).send('Unimplemented')
    end
  end
end