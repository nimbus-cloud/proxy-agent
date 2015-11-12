require 'faraday'
require 'json'

require_relative 'squid'

class Agent

  def initialize(logger, squid, config_fetcher, static_users)
    @logger = logger
    @squid = squid
    @config_fetcher = config_fetcher
    @model = fetch_model
    @model.merge!(static_users)
    @squid.reload_configuration(@model)
    @mutex = Mutex.new
  end

  def new_user(username, passowrd)
    @logger.info "Agent creating new user: #{username}"
    @mutex.synchronize do
      tmp_model = @model.dup
      tmp_model[username] = {'htpasswd' => passowrd, 'allow_rules' => []}
      @squid.reload_configuration(tmp_model)
      @model = tmp_model
    end
  end

  def delete_user(username)
    @logger.info "Agent deleting user: #{username}"
    @mutex.synchronize do
      tmp_model = @model.dup
      tmp_model.delete(username)
      @squid.reload_configuration(tmp_model)
      @model = tmp_model
    end
  end

  def apply_schema(username, allow_rules)
    @logger.info "Agent applying schema for user: #{username}, allow rules: #{allow_rules}"
    @mutex.synchronize do
      tmp_model = @model.dup
      tmp_model[username]['allow_rules'] = allow_rules
      @squid.reload_configuration(tmp_model)
      @model = tmp_model
    end
  end

  private

  def fetch_model
    @logger.info('Fetching full config from broker')
    @config_fetcher.model_from_broker
  end

end

