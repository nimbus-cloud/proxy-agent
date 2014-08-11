require 'faraday'
require 'em-synchrony/em-http'
require 'json'

class Agent
  
  def initialize(logger)
    @logger = logger
    Fiber.new { start }.resume
  end
  
  def register_module(model)
    @logger.debug "Adding module #{model.get_module_name}"
    @modules.push(model)
  end
  
  def start
    @logger.debug "Event machine starting."
    @logger.info "connecting to rabbitmq..."
    @rabbit_conn = Bunny.new($amqp_url)
    @rabbit_conn.start
    @rabbit_ch = @rabbit_conn.create_channel
    @rabbit_exch = @rabbit_ch.fanout("proxy_events")
    @rabbit_queue = @rabbit_ch.queue("", :auto_delete => true, :exclusive => true)
    @rabbit_queue.bind(@rabbit_exch)
    @logger.info "...success"
    @modules = []  
    @rabbit_queue.subscribe() do |_, _, message|
      Fiber.new { 
        begin
          process_update(message)
        rescue Exception => e
          @logger.error("Failed to process \"#{message}\". #{e.message}\n#{e.backtrace}")
        end 
      }.resume
    end
    
    @model = {}
    # lets fall over and rely on monit if we fail to load on startup
    EM.next_tick do
      Fiber.new {
        begin
          refresh_model
        rescue Exception => e
          @logger.error("Failed to perform our full data refresh #{e.message}\n#{e.backtrace}")
        end
        
      }.resume
    end
    
    EM.add_periodic_timer(10) do
      Fiber.new {
        begin
          refresh_model
        rescue Exception => e
          @logger.error("Failed to perform our full data refresh #{e.message}\n#{e.backtrace}")
        end
      }.resume
    end
  end
  
  def refresh_model
    new_model_str = load_from_url
    new_model = JSON.parse(new_model_str)
    
    if @model != new_model
      @logger.info("Updating model from full refresh")
      @model = new_model
      @modules.each do |mod|
        mod.reload_module(@model)   
      end
    else
      @logger.info("Model in memory is correct")
    end
  end

  def load_from_url
    conn = Faraday.new(:url => "#{$app_settings['broker_end_point']}/fullconfig")
    conn.use Faraday::Adapter::EMSynchrony
    conn.basic_auth($app_settings['broker_username'], $app_settings['broker_password'])
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

