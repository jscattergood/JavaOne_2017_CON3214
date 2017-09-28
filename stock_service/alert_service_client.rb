require './common/common'

class AlertServiceClient
  include Common

  def initialize(url, client)
    @url = url
    @client = client
  end

  def send_event(event)
    uri = to_uri("#{ @url }/stock")
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.body { |b| b.text(event.to_json) }
    end
  end
end