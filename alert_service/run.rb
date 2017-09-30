require 'active_record'
require 'activerecord-jdbc-adapter'
require './common/common'
require './common/metrics_reporter'
require_relative 'db/startup'
require_relative 'model/alert'
require_relative 'notification_service_client'

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
    end
  )

  server.handlers do |chain|
    chain.files do |f|
      f.dir('public').index_files('index.html')
    end

    chain.post('stock') do |ctx|
      http_client = ctx.get(HttpClient.java_class)
      notification_service_client = NotificationServiceClient.new(
        ENV['SA_NOTIFICATION_SERVICE_URL'],
        http_client
      )

      ctx.request.body
        .map { |b| JSON.parse(b.text) }
        .map { |event| puts event; event}
        .flat_map { |event| find_matches(event) }
        .flat_map { |alerts| send_messages(notification_service_client, alerts) }
        .then { ctx.render('OK') }
    end

    chain.post('alert') do |ctx|
      ctx.response.status(501).send('Unimplemented')
    end

    chain.patch('alert') do |ctx|
      ctx.response.status(501).send('Unimplemented')
    end
  end

  def find_matches(event)
    Promise.async do |d|
      results = Alert.where(ticker: event['ticker'])
      matches = results.select do |a|
        case a.predicate
        when 'GT'
          event['price'].to_f > a.value
        when 'LT'
          event['price'].to_f < a.value
        when 'EQ'
          event['price'].to_f == a.value
        else
          false
        end
      end
      notifications = matches.map do |a|
        {
          ticker: event['ticker'],
          price: event['price'],
          phone: a.phone
        }
      end
      d.success(notifications)
    end
  end

  def send_messages(client, alerts)
    Streams.publish(alerts)
      .flat_map { |a| client.send_notification(a)}
      .to_list
  end
end