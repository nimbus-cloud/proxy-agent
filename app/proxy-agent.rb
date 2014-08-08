require 'sinatra'
require 'sinatra/reloader' if development?
require 'bunny'
require 'logger'
require 'json'
require 'net/http'
require 'yaml'
require 'eventmachine'
require 'rack/fiber_pool'

class ProxyAgent  < Sinatra::Base
  
  # I think rack fiber pool may well be broken all requests coming in on the same fiber
  use Rack::FiberPool, size: 20
  

  
  get '/' do
    "Proxy Agent"
  end
  
  
end