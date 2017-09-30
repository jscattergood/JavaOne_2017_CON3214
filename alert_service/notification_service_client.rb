require './common/common'

class NotificationServiceClient
  include Common

  def initialize(url, client)
    @url = url
    @client = client
  end

  def send_notification(event)
    uri = to_uri("#{ @url }/notification")
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.body { |b| b.text(event.to_json) }
    end
  end
end