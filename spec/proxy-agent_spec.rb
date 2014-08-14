require 'spec_helper'
require File.join(File.dirname(__FILE__), '../app/', 'proxy-agent.rb')

describe ProxyAgent do
  def app
    @app ||= ProxyAgent
  end
  
  before(:all) do
    ProxyAgent.set :logging, false
    ProxyAgent.set :run, false
    ProxyAgent.set :raise_errors, true
    
  end
      
  describe "Root URL" do
    before(:each) do
      get '/'
    end
      
    it 'should return return a 200' do
      expect(last_response.status).to eq(200)
    end
    
    it 'should return "Proxy Agent"' do
      expect(last_response.body).to eq("Proxy Agent")
    end
  end
end
