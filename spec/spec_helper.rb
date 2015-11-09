ENV['RACK_ENV'] = 'test'

require 'rack/test'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # Too much conflicting information on the internet about rspec
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  
end
