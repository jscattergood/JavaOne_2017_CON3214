require './common/common'
require 'json'

class AutoscalerServiceClient
  include Common

  def initialize(url, client)
    @url = url
    @client = client
  end

  def scale_up(service)
    puts "scaling up #{service}..."
    url = "#{ @url }/v1/orbiter/handle/autoswarm/#{ENV['WA_STACK_NAME']}_#{service}/up"
    puts url
    uri = to_uri(url)
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
    end
  end

  def scale_down(service)
    puts "scaling down #{service}..."
    url = "#{ @url }/v1/orbiter/handle/autoswarm/#{ENV['WA_STACK_NAME']}_#{service}/down"
    puts url
    uri = to_uri(url)
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
    end
  end

end