require 'faraday'
require 'json'

class ConfigFetcher

  def initialize(host, user, password)
    @host = host
    @user = user
    @password = password
  end

  def model_from_broker
    conn = Faraday.new(:url => "#{@host}/fullconfig")
    conn.basic_auth(@user, @password)
    response = conn.get
    if response.status.to_i != 200
      raise "Failed to refresh config from broker http interface. #{response.status} #{response.body}"
    end
    JSON.parse(response.body)
  end

end

