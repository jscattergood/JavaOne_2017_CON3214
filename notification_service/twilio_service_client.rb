require './common/common'

class TwilioServiceClient
  include Common

  def initialize(client)
    @url = 'https://api.twilio.com/2010-04-01'
    @client = client
  end

  def send_notification(event)
    uri = to_uri("#{ @url }/Accounts/#{ENV['SA_TWILIO_SID']}/Messages")
    @client.post(uri) do |req|
      req.basic_auth(ENV['SA_TWILIO_SID'], ENV['SA_TWILIO_AUTH'])
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
      req.body do |b|
        b.type('application/x-www-form-urlencoded')
        b.text(
          URI.encode_www_form(
            [
              ['From', ENV['SA_TWILIO_NUMBER']],
              ['To', event['phone']],
              ['Body', "Alert is triggered: #{event['ticker']} with price #{event['price']}"]
            ]
          )
        )
      end
    end
  end
end