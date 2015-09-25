require 'sinatra'
require 'sinatra/reloader' if development?
require 'logger'
require 'eventmachine'
require 'rack/fiber_pool'

$stdout.sync = true
$stderr.sync = true
$logger = Logger.new($stdout)

class ProxyAgent  < Sinatra::Base
  
  # I think rack fiber pool may well be broken all requests coming in on the same fiber. Comment out for now
  # use Rack::FiberPool, size: 20
  register Sinatra::ActiveRecordExtension

  use Rack::CommonLogger, $logger

  configure :development do
    set :database, 'sqlite3:db/development.sqlite3'
  end

  configure :production do
    set :database, 'sqlite3:/var/vcap/store/sharedfs/sharedfs.sqlite3'
  end

  configure do
    $logger.info('*==========================*')
    $logger.info('*cf-sharedfs agent starting*')
    $logger.info('*==========================*')

    settings_filename = ENV['SETTINGS_FILENAME'] ? ENV['SETTINGS_FILENAME'] : File.dirname(__FILE__) + '/../config/settings.yml'
    $logger.info("Loading settings file #{settings_filename}")
    $app_settings ||= YAML.load_file(settings_filename)

    set :service, UserProvisioner.new($logger, $app_settings)

    ActiveRecord::Base.logger = Logger.new($stdout)

    $logger.info 'verifying existing users...'
    settings.service.verify_users_exist!
    $logger.info 'started!'
  end

  before '*' do
    content_type :json
  end

    
  get '/' do
    "Proxy Agent"
  end

  put '/provision/:username/:htpasswd' do |username, htpasswd|
    $logger.info "provisioning proxy user #{username}"
    success, msg = service.provision(username, htpasswd)

    {
        success: success,
        :msg => msg
    }.to_json
  end

  delete '/unprovision/:username' do |username|
    $logger.info "unprovisioning proxy user: #{username}"
    success, msg = service.unprovision(username)

    {
        :success => success,
        :msg => msg
    }.to_json
  end

  get '/credentials/:username' do |username|
    $logger.info "getting credentials for user: #{username}"
    success, msg, credentials = service.credentials(username)

    {
        :success => success,
        :msg => msg,
        :credentials => credentials
    }.to_json
  end

  private

  def service
    settings.service
  end

end