require 'bundler/setup'
Bundler.require
require 'java'
require 'json'

java_import 'java.time.Duration'

class AlarmServiceClient
  def initialize(url, client)
    @url = url
    @client = client
  end

  def send_weather_event(event)
    uri = java.net.URI.new("#{ @url }/weather")
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.body { |b| b.text(event.to_json) }
    end
  end
end