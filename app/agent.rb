require 'faraday'
require 'json'

require_relative 'squid'

class Agent

  def initialize(logger, squid, config_fetcher, static_users)
    @logger = logger
    @squid = squid
    @config_fetcher = config_fetcher
    @static_users = static_users
  end

  # TODO: this is not thread safe
  # TODO: handle @model instance properly
  # TODO: need to call this first to initialize @model
  def refresh_model
    new_model = @config_fetcher.model_from_broker
    new_model.merge!(@static_users)

    if @model != new_model
      @logger.info('Updating model from full refresh')
      @squid.reload_configuration(@model)
      @model = new_model
    end
  end

  def new_user(username, passowrd)
    @logger.info "Agent creating new user: #{username}"
    @model[username] = {'htpasswd' => passowrd, 'allow_rules' => []}
    @squid.reload_configuration(@model)
  end

  def delete_user(username)
    @logger.info "Agent deleting user: #{username}"
    @model.delete(username)
    @squid.reload_configuration(@model)
  end

  def apply_schema(username, allow_rules)
    @logger.info "Agent applying schema for user: #{username}, allow rules: #{allow_rules}"
    @model[username]['allow_rules']= allow_rules
    @squid.reload_configuration(@model)
  end

end

