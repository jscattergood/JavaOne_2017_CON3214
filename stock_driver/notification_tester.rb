require 'net/http'
require 'json'

# This is a basic script that sends random stock events to the stock service as fast as possible

uri = URI.parse("#{ENV['SA_NOTIFICATION_SERVICE_URL']}/notification")
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
request.body = {
  ticker: 'AAAAA',
  price: '49',
  phone: ENV['TO_PHONE'],
  id: '1'
}.to_json

response = http.request(request)
puts "#{Time.now}: #{response.code}"
