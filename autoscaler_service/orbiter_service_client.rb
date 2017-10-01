require './common/common'
require 'json'

class OrbiterServiceClient
  include Common

  def initialize(url, client)
    @url = url
    @client = client
  end

  def scale_up(service)
    Common::Log.info "scaling up #{service}..."
    uri = to_uri("#{ @url }/v1/orbiter/handle/autoswarm/#{ENV['SA_STACK_NAME']}_#{service}/up")
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
    end
  end

  def scale_down(service)
    Common::Log.info "scaling down #{service}..."
    uri = to_uri("#{ @url }/v1/orbiter/handle/autoswarm/#{ENV['SA_STACK_NAME']}_#{service}/down")
    @client.post(uri) do |req|
      req.connect_timeout(Duration.of_seconds(5))
      req.read_timeout(Duration.of_seconds(5))
    end
  end

end