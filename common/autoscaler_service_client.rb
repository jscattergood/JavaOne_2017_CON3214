require './common/common'
require 'json'

class AutoscalerServiceClient
  include Common

  def initialize(url, client)
    @url = url
    @client = client
  end

  def send_event(event)
    uri = to_uri("#{ @url }/metrics")
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.body { |b| b.text(
        {
          service: ENV['WA_SERVICE_NAME'],
          metrics: event
        }.to_json
      )}
    end
  end
end