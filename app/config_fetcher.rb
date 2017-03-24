require 'faraday'
require 'json'

class ConfigFetcher

  def initialize(managed_by_broker, host, user, password)
    @config_fetcher = (managed_by_broker ? FullConfigFromBroker.new(host, user, password) : EmptyConfig.new())
  end

  def model_from_broker
    @config_fetcher.model_from_broker
  end

  class FullConfigFromBroker
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

  class EmptyConfig
    def initialize

    end

    def model_from_broker
      {}
    end
  end

end

