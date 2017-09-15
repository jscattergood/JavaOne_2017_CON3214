require 'net/http'
require 'json'

# This is a basic script that sends random weather events to the weather service as fast as possible

threads = []
5.times do
  threads << Thread.start do
    uri = URI.parse("#{ENV['WA_WEATHER_SERVICE_URL']}/weather")
    http = Net::HTTP.new(uri.host, uri.port)
    backoff = 1
    done = false
    until done
      request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
      request.body = {
        location: "#{Random.rand(10000..99999)}",
        temperature: "#{Random.rand(0..100)}"
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