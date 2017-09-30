require 'net/http'
require 'json'

# This is a basic script that sends random stock events to the stock service as fast as possible

threads = []
5.times do
  threads << Thread.start do
    uri = URI.parse("#{ENV['SA_STOCK_SERVICE_URL']}/stock")
    http = Net::HTTP.new(uri.host, uri.port)
    backoff = 1
    done = false
    until done
      ticker = []
      5.times do
        ticker << ('A'.ord + Random.rand(0..25)).chr
      end
      request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
      request.body = {
        ticker: "#{ticker.join('')}",
        price: "#{Random.rand(1..100)}"
      }.to_json

      response = http.request(request)
      puts "#{Time.now}: #{response.code}"
      if response.code == '429' || response.code >= '500'
        puts "backing off for #{backoff} secs"
        sleep(backoff)
        backoff *= 2
      else
        backoff = 1
      end
    end
  end
end

threads.each(&:join)