require './common/common'

class WeatherUndergroundClient
  def initialize(api_key, client)
    @api_key = api_key
    @client = client
  end

  def current_conditions(location)
    uri = java.net.URI.new("http://api.wunderground.com/api/#{@api_key}/conditions/q/#{location}.json")
    @client.get(uri)
  end
end