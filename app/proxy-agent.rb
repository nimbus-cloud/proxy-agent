require 'sinatra'
require 'logger'
require 'yaml'

require_relative 'agent'

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
    set :service, Agent.new($logger, squid)

  end

  get '/' do
    'Proxy Agent'
  end

  # TODO: refresh_model on startup
  # TODO: refresh_model at interval (currently 60s)
  # TODO: route for handling changes: process_update(message)

  # TODO: rest of the api

  private

  def service
    settings.service
  end

end