require 'net/http'
require 'json'

uri = URI.parse("#{ENV['SA_NOTIFICATION_SERVICE_URL']}/notification")
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
request.body = {
  ticker: 'AAAAA',
  price: "#{Random.rand(1..100)}",
  phone: ENV['SA_ALERT_PHONE']
}.to_json

response = http.request(request)
puts "#{Time.now}: #{response.body}"
