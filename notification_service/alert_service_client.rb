require 'json'
require './common/common'

class AlertServiceClient
  include Common

  def initialize(url, client)
    @url = url
    @client = client
  end

  def send_success(id)
    uri = to_uri("#{ @url }/rule/#{id}")
    @client.request(uri) do |req|
      fields = {
        last_notified: Time.now
      }
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.patch
      req.body { |b| b.text(fields.to_json) }
    end
  end

  def send_failure(id)
    uri = to_uri("#{ @url }/rule/#{id}")
    @client.request(uri) do |req|
      fields = {
        last_triggered: nil,
        last_notified: nil
      }
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.patch
      req.body { |b| b.text(fields.to_json) }
    end
  end

end