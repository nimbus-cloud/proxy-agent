require 'spec_helper'
require 'logger'
require File.join(File.dirname(__FILE__), '../app/', 'squid_config.rb')
require_relative 'support/bunny_mock'
require "rspec/em"
require "em-synchrony"



describe Agent do
  
  before(:all) do
    $logger = Logger.new("/dev/null")
    #$logger = Logger.new(STDOUT)
    $app_settings = {}
  end
  
  describe "Startup" do 
  
    before(:each) do
      $amqp_url="fake"
      @bunny_mock = BunnyMock.new
      Bunny.stub(:new).and_return(@bunny_mock)
      @agent = Agent.new($logger)
      
     
      @fake_model = {"61dcba8056" => {"htpasswd" => "$apr1$/TBHZrCT$l2hnJ1K22k5fKKZXSmZtB1","allow_rules" => ["www.theregister.co.uk","shop.sky.com"]},"5ddcc1b181" => {"htpasswd" => "$apr1$fWngM21J$ptHJ8By9xyvEps18aqbww/","allow_rules" => ["www.google.com"]}}
      @agent.stub(:get_faraday_url_connection) do
      
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get('/') { |env| [ 200, {}, @fake_model.to_json] }
        end
        conn = Faraday.new do |builder|
          builder.adapter :test, stubs
        end
        conn
      end
    end
    
    it 'should start a periodic timer every 60 seconds to refresh model' do
      EM.should_receive(:add_periodic_timer).with(60)
      with_event_machine do
        @agent.start_in_fiber
        done
      end
    end
    
    it 'should contain a valid model' do
      with_event_machine do
        @agent.start_in_fiber
        done
      end
      expect(@agent.get_model).to eq(@fake_model)
    end
    
    it 'should adapt the model when sent a new_user message' do
      @agent.should_receive(:create_rabbit_mq_connection).once
      
      exch = @bunny_mock.fanout("proxy_events")
      queue = @bunny_mock.queue("")
      queue.bind(exch)
      
      @agent.instance_variable_set(:@rabbit_queue, queue)
      
      exch.publish({'type' => 'new_user', 'username' => 'testuser', 'htpasswd' => 'kdnsugu'}.to_json)
      with_event_machine do
        @agent.start_in_fiber
        done
      end
      @fake_model['testuser'] = {"htpasswd" => "kdnsugu","allow_rules" => []}
      expect(@agent.get_model).to eq(@fake_model)
    end
    
    it 'should adapt the model when sent a delete_user message' do
      @agent.should_receive(:create_rabbit_mq_connection).once
      
      exch = @bunny_mock.fanout("proxy_events")
      queue = @bunny_mock.queue("")
      queue.bind(exch)
      
      @agent.instance_variable_set(:@rabbit_queue, queue)
      
      exch.publish({'type' => 'delete_user', 'username' => '61dcba8056'}.to_json)
      with_event_machine do
        @agent.start_in_fiber
        done
      end
      @fake_model.delete('61dcba8056')
      expect(@agent.get_model).to eq(@fake_model)
    end
    
    it 'should adapt the model when sent an apply_schema message' do
      @agent.should_receive(:create_rabbit_mq_connection).once
      
      exch = @bunny_mock.fanout("proxy_events")
      queue = @bunny_mock.queue("")
      queue.bind(exch)
      
      @agent.instance_variable_set(:@rabbit_queue, queue)
      
      exch.publish({'type' => 'apply_schema', 'username' => '61dcba8056', 'allow_rules' => ["a", "b"]}.to_json)
      with_event_machine do
        @agent.start_in_fiber
        done
      end
      @fake_model['61dcba8056']['allow_rules'] = ["a", "b"]
      expect(@agent.get_model).to eq(@fake_model)
    end
  
    it 'should update a fake model we subscribe for updates' do
      
      class FakeModule 
      end
      
      fake_module = FakeModule.new
      fake_module.should_receive(:get_module_name).once.and_return("fake_module")
      fake_module.should_receive(:reload_module).once
      
      @agent.register_module(fake_module)
      
      with_event_machine do
        @agent.start_in_fiber
        done
      end
      
    end
    
    it 'should merge static users into the model' do
      $app_settings['static_users']=[]
      user = {}
      user['username']= 'test'
      user['htpasswd']= 'test'
      user['sites'] = [ 'mail.google.com', 'foobar.com' ]
      $app_settings['static_users'].push(user)
      @fake_model['test']={}
      @fake_model['test']['htpasswd']='test'
      @fake_model['test']['allow_rules'] = [ 'mail.google.com', 'foobar.com' ]
      with_event_machine do
        @agent.start_in_fiber
        done
      end
      expect(@agent.get_model).to eq(@fake_model)
      $app_settings['static_users']=[]  
    end
    
  end
end
