require 'net/http'
require 'json'

# This is a basic script that sends random stock events to the stock service as fast as possible

uri = URI.parse("#{ENV['SA_STOCK_SERVICE_URL']}/stock")
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
request.body = {
  ticker: 'AAAAA',
  price: "49"
}.to_json

response = http.request(request)
puts "#{Time.now}: #{response.code}"
