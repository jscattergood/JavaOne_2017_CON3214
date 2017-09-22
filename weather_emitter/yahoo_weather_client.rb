require './common/common'

class YahooWeatherClient
  def initialize(api_key, client)
    @api_key = api_key
    @client = client
  end

  def current_conditions(location)
    query = "select item.condition from weather.forecast where woeid in (select woeid from geo.places(1) where text='#{location}')"
    env = 'store://datatables.org/alltableswithkeys'
    url = URI.encode("https://query.yahooapis.com/v1/public/yql?q=#{query}&format=json&env=#{env}")
    uri = java.net.URI.new(url)
    @client.get(uri)
  end
end