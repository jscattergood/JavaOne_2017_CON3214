require 'json'
require './common/common'

class AlertServiceClient
  include Common

  def initialize(url, client)
    @url = url
    @client = client
  end

  def send_success(event)
    uri = to_uri("#{ @url }/alert")
    @client.patch(uri) do |req|
      update = {
        id: event.id,
        last_notified: Time.now
      }
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.body { |b| b.text(update.to_json) }
    end
  end

  def send_failure(event)
    uri = to_uri("#{ @url }/alert")
    @client.patch(uri) do |req|
      update = {
        id: event.id,
        last_triggered: nil,
        last_notified: nil
      }
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.body { |b| b.text(update.to_json) }
    end
  end

end