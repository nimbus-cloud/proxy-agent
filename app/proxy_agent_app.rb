require 'sinatra'
require 'logger'
require 'yaml'
require 'json'

require_relative 'agent'
require_relative 'config_fetcher'

STDOUT.sync = true
STDERR.sync = true
$logger = Logger.new(STDOUT)

class ProxyAgentApp < Sinatra::Base

  use Rack::CommonLogger, $logger

  configure do
    $logger.info('========================')
    $logger.info('proxy agent starting')
    $logger.info('========================')

    settings_filename = ENV['SETTINGS_FILENAME'] ? ENV['SETTINGS_FILENAME'] : File.dirname(__FILE__) + '/../config/settings.yml'
    $logger.info("Loading settings file #{settings_filename}")
    settings ||= YAML.load_file(settings_filename)

    reload_cmd = settings['squid']['reload_command']
    conf_dir = settings['squid']['config_dir']
    pass_file = settings['squid']['htpasswd_file']

    squid = Squid.new($logger, reload_cmd, conf_dir, pass_file)
    config_fetcher = ConfigFetcher.new(settings['managed_by_broker'],
                                       settings['broker_end_point'],
                                       settings['broker_username'],
                                       settings['broker_password'])

    static_users = {}
    if settings['static_users']
      settings['static_users'].each do |user|
        u = {}
        u['htpasswd'] = user['htpasswd']
        u['allow_rules'] = user['sites']
        static_users[user['username']] = u
      end
    end

    set :service, Agent.new($logger, squid, config_fetcher, static_users)
    $logger.info('Proxy broker started!')
  end

  before '*' do
    content_type :json
  end

  get '/' do
    {:msg => 'Proxy Agent'}.to_json
  end

  put '/newuser' do
    begin
      request.body.rewind
      payload = JSON.parse(request.body.read)
      service.new_user(payload['username'], payload['password'])
      {}.to_json
    rescue => e
      status 500
      msg = "Failed to create new user: #{e.message}"
      $logger.error(msg)
      {:message => msg}.to_json
    end
  end

  delete '/deleteuser/:username' do |username|
    begin
      service.delete_user(username)
      {}.to_json
    rescue => e
      status 500
      msg = "Failed to delete user: #{e.message}"
      $logger.error(msg)
      {:message => msg}.to_json
    end
  end

  post '/applyschema' do
    begin
      request.body.rewind
      payload = JSON.parse(request.body.read)
      service.apply_schema(payload['username'], payload['allow_rules'])
      {}.to_json
    rescue => e
      status 500
      msg = "Failed to apply schema: #{e.message}"
      $logger.error(msg)
      {:message => msg}.to_json
    end
  end

  private

  def service
    settings.service
  end

end
