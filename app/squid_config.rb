require 'faraday'
require 'em-synchrony/em-http'
require 'json'
require 'bunny'
require 'eventmachine'

class SquidConfig
  
  def initialize(logger)
    @logger = logger
    @modules = []
  end
  
  def register_module(model)
    @logger.debug "Adding module #{model.get_module_name}"
    @modules.push(model)
  end
  
  # def start_in_fiber
  #   Fiber.new { start }.resume
  # end
  #
  # def start
  #   @logger.debug "Event machine starting."
  #   @logger.info "connecting to rabbitmq..."
  #   create_rabbit_mq_connection
  #   @logger.info "...success"
  #
  #   @model = {}
  #   # lets fall over and rely on monit if we fail to load on startup
  #   EM.next_tick do
  #     Fiber.new {
  #       begin
  #         refresh_model
  #       rescue Exception => e
  #         @logger.error("Failed to perform our full data refresh #{e.message}\n#{e.backtrace}")
  #       end
  #     }.resume
  #
  #     @rabbit_queue.subscribe() do |_, _, message|
  #       Fiber.new {
  #         begin
  #           process_update(message)
  #         rescue Exception => e
  #           @logger.error("Failed to process \"#{message}\". #{e.message}\n#{e.backtrace}")
  #           raise e
  #         end
  #       }.resume
  #     end
  #   end
  #
  #
  #   EM.add_periodic_timer(60) do
  #     Fiber.new {
  #       begin
  #         refresh_model
  #       rescue Exception => e
  #         @logger.error("Failed to perform our full data refresh #{e.message}\n#{e.backtrace}")
  #       end
  #     }.resume
  #   end
  # end
  
  #def create_rabbit_mq_connection
  #  @rabbit_conn = Bunny.new($amqp_url)
  #  @rabbit_conn.start
  #  @rabbit_ch = @rabbit_conn.create_channel
  #  @rabbit_exch = @rabbit_ch.fanout("proxy_events")
  #  @rabbit_queue = @rabbit_ch.queue("", :auto_delete => true, :exclusive => true)
  #  @rabbit_queue.bind(@rabbit_exch)
  #end

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

    
  def refresh_model
    new_model_str = load_from_url
    new_model = JSON.parse(new_model_str)

    new_model = merge_static_users(new_model)
    
    if @model != new_model
      @logger.info("Updating model from full refresh")
      @model = new_model
      @modules.each do |mod|
        mod.reload_module(@model)   
      end
    end
  end
  
  
  def get_faraday_url_connection
    conn = Faraday.new(:url => "#{$app_settings['broker_end_point']}/fullconfig")
    conn.use Faraday::Adapter::EMSynchrony
    conn.basic_auth($app_settings['broker_username'], $app_settings['broker_password'])
    conn
  end
  
  def get_model
    @model
  end

  def load_from_url
    conn = get_faraday_url_connection
    response=conn.get()
    response.status.to_i == 200 or raise "Failed to refresh config from broker http interface. #{response.status} #{response.body}"
    response.body
  end
    
  def process_update(message)
    @logger.info "Received message #{message}"
    $logger.debug "Before #{@model.to_json}"
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
    @modules.each do |mod|
      mod.reload_module(@model)   
    end
    $logger.debug "After #{@model.to_json}"
  end
end

