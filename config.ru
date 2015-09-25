dir = File.dirname(__FILE__)
require File.join(dir, 'app/proxy-agent')
require File.join(dir, 'app/config')
require File.join(dir, 'app/environments')

run Rack::URLMap.new("/" => ProxyAgent.new)

#EM.schedule do
#  $agent = Agent.new($logger)
#  Dir[File.dirname(__FILE__) + '/app/modules/*.rb'].each {|file| require file }
#  $agent.register_module(Squid.new($logger))
#  $agent.start_in_fiber
#
#end
