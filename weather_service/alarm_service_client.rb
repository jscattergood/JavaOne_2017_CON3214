require 'bundler/setup'
Bundler.require
require 'java'
require 'json'


class AlarmServiceClient
  def initialize(url, client)
    @url = url
    @client = client
  end

  def send_weather_event(event)
    uri = java.net.URI.new("#{ @url }/weather")
    @client.post(uri) do |req|
      req.body { |b| b.text(event.to_json) }
    end
  end
end