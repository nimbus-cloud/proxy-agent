require 'sinatra'
require 'logger'
require 'yaml'
require 'json'

require_relative 'agent'
require_relative 'config_fetcher'

STDOUT.sync = true
$logger = Logger.new(STDOUT)

class ProxyAgent  < Sinatra::Base

  configure do
    $logger.info('========================')
    $logger.info('proxy agent starting')
    $logger.info('========================')

    settings_filename = ENV['SETTINGS_FILENAME'] ? ENV['SETTINGS_FILENAME'] : File.dirname(__FILE__) + '/../config/settings.yml'
    $logger.info("Loading settings file #{settings_filename}")
    $app_settings ||= YAML.load_file(settings_filename)

    reload_cmd = $app_settings['squid']['reload_command']
    conf_dir = $app_settings['squid']['config_dir']
    pass_file = $app_settings['squid']['htpasswd_file']

    squid = Squid.new($logger, reload_cmd, conf_dir, pass_file)
    config_fetcher = ConfigFetcher.new($app_settings['broker_end_point'],
                                       $app_settings['broker_username'],
                                       $app_settings['broker_password'])

    static_users = {}
    if $app_settings['static_users']
      $app_settings['static_users'].each do |user|
        u = {}
        u['htpasswd'] = user['htpasswd']
        u['allow_rules'] = user['sites']
        static_users[user['username']] = u
      end
    end

    set :service, Agent.new($logger, squid, config_fetcher, static_users)
  end

  before '*' do
    content_type :json
  end

  get '/' do
    {:msg => 'Proxy Agent'}.to_json
  end


  # TODO: refresh_model on startup ???
  # TODO: refresh_model at interval (currently 60s) ??? - proper handling of singleton model value
  # TODO: error handling ???

  put '/newuser/:username/:password' do |username, password|
    service.new_user(username, password)
  end

  delete '/deleteuser/:username' do |username|
    service.delete_user(username)
  end

  post '/applyschema' do
    request.body.rewind
    payload = JSON.parse(request.body.read)
    service.apply_schema(payload['username'], payload['allow_rules'])
  end

  private

  def service
    settings.service
  end

end