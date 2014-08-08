dir = File.dirname(__FILE__)
require File.join(dir, 'app/proxy-agent')
require File.join(dir, 'app/agent')
require File.join(dir, 'app/environments')

run Rack::URLMap.new("/" => ProxyAgent.new)

EM.schedule do
  $agent = Agent.new($logger)
end
