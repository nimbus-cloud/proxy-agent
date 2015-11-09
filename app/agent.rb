require 'faraday'
require 'json'

require_relative 'squid'

class Agent

  def initialize(logger, squid)
    @logger = logger
    @squid = squid
  end

  def refresh_model
    new_model_str = load_from_url
    new_model = JSON.parse(new_model_str)
    new_model = merge_static_users(new_model)

    if @model != new_model
      @logger.info('Updating model from full refresh')
      @model = new_model
      @squid.reload_configuration(@model)
    end
  end

  def process_update(message)
    @logger.info "Received message #{message}"
    @logger.debug "Before #{@model.to_json}"
    message_obj = JSON.parse(message, :symbolize_names => true)
    if message_obj[:type] == 'new_user'
      @model[message_obj[:username]] = {}
      @model[message_obj[:username]]['htpasswd'] = message_obj[:htpasswd]
      @model[message_obj[:username]]['allow_rules'] = []
    elsif message_obj[:type] == 'delete_user'
      @model.delete(message_obj[:username])
    elsif message_obj[:type] == 'apply_schema'
      @model[message_obj[:username]]['allow_rules']= message_obj[:allow_rules]
    end
    @squid.reload_configuration(@model)
    @logger.debug "After #{@model.to_json}"
  end

  private

  def merge_static_users(model_in)
    model_out = model_in
    if $app_settings['static_users']
      $app_settings['static_users'].each do |user|
        model_out[user['username']]={}
        model_out[user['username']]['htpasswd']=user['htpasswd']
        model_out[user['username']]['allow_rules']=user['sites']
      end
    end

    model_out
  end

  def load_from_url
    conn = get_faraday_url_connection
    response=conn.get()
    response.status.to_i == 200 or raise "Failed to refresh config from broker http interface. #{response.status} #{response.body}"
    response.body
  end

  def get_faraday_url_connection
    conn = Faraday.new(:url => "#{$app_settings['broker_end_point']}/fullconfig")
    conn.use Faraday::Adapter::EMSynchrony
    conn.basic_auth($app_settings['broker_username'], $app_settings['broker_password'])
    conn
  end

end

