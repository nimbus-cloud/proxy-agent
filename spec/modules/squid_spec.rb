require 'spec_helper'
require 'logger'
require File.join(File.dirname(__FILE__), '../../app/modules', 'squid.rb')
require 'fakefs/spec_helpers'

describe Squid do
  
  before(:all) do
    $logger = Logger.new("/dev/null")
  end
  
  before(:each) do
    include FakeFS::SpecHelpers
    $app_settings={}
    $app_settings['squid']={}
    $app_settings['squid']['reload_command'] = "echo '1'"
    $app_settings['squid']['config_dir'] = '/tmp'
    $app_settings['squid']['htpasswd_file'] = '/tmp/htpasswd' 
    @squid = Squid.new($logger)
  end
  
  it "should respond to call to get its name" do
    expect(@squid.get_module_name).to eq("squid")
  end
  
  context "implementing reload" do
    include FakeFS::SpecHelpers
    
    before(:each) do
      @model = {"61dcba8056" => {"htpasswd" => "$apr1$/TBHZrCT$l2hnJ1K22k5fKKZXSmZtB1","allow_rules" => ["www.theregister.co.uk","shop.sky.com"]},"5ddcc1b181" => {"htpasswd" => "$apr1$fWngM21J$ptHJ8By9xyvEps18aqbww/","allow_rules" => ["www.google.com"]}}
      FileUtils.mkdir_p("/tmp")
    end
    
    it 'should write htpasswd file' do
      @squid.reload_module(@model)
      expect(File.exist?("/tmp/htpasswd")).to eq(true)
    end
        
    it 'should write users.conf file into squid conf.d' do
      @squid.reload_module(@model)
      expect(File.exist?("/tmp/users.conf")).to eq(true)
    end
    
    it 'should create group dir' do
      @squid.reload_module(@model)
      expect(File.exist?("/tmp/groups")).to eq(true)
    end
    
    it 'should create group files' do
      @squid.reload_module(@model)
      expect(File.exist?("/tmp/groups/group_61dcba8056.txt")).to eq(true)
      expect(File.exist?("/tmp/groups/group_5ddcc1b181.txt")).to eq(true)
    end
    
    it 'should create sites dir' do
      @squid.reload_module(@model)
      expect(File.exist?("/tmp/sites")).to eq(true)
    end
    
    it 'should create sites files' do
      @squid.reload_module(@model)
      expect(File.exist?("/tmp/sites/sites_61dcba8056.txt")).to eq(true)
      expect(File.exist?("/tmp/sites/sites_5ddcc1b181.txt")).to eq(true)
    end
  
    it 'should call the squid reload script' do
      @squid.should_receive(:execute_command).once
      @squid.reload_module(@model)
    end
    
  end

end