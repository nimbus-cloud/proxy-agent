require 'logger'
require 'fakefs/spec_helpers'
require_relative '../app/squid'

describe Squid do
  
  before(:all) do
    STDOUT.sync = true
    $logger = Logger.new(STDOUT)
  end
  
  before(:each) do
    reload_cmd = "echo '1'"
    conf_dir = '/tmp'
    pass_file = '/tmp/htpasswd'
    @squid = Squid.new($logger, reload_cmd, conf_dir, pass_file)
  end
  
  context 'implementing reload' do
    include FakeFS::SpecHelpers
    
    before(:each) do
      @model = {'61dcba8056' => { 'htpasswd' => '$apr1$/TBHZrCT$l2hnJ1K22k5fKKZXSmZtB1',
                                  'allow_rules' => %w(www.theregister.co.uk shop.sky.com)},
                                  '5ddcc1b181' => {'htpasswd' => '$apr1$fWngM21J$ptHJ8By9xyvEps18aqbww/', 'allow_rules' => ['www.google.com']}}
      FileUtils.mkdir_p('/tmp')
    end
    
    it 'should write htpasswd file' do
      @squid.reload_configuration(@model)
      expect(File.exist?('/tmp/htpasswd')).to eq(true)
    end
        
    it 'should write users.conf file into squid conf.d' do
      @squid.reload_configuration(@model)
      expect(File.exist?('/tmp/users.conf')).to eq(true)
    end
    
    it 'should create group dir' do
      @squid.reload_configuration(@model)
      expect(File.exist?('/tmp/groups')).to eq(true)
    end
    
    it 'should create group files' do
      @squid.reload_configuration(@model)
      expect(File.exist?('/tmp/groups/group_61dcba8056.txt')).to eq(true)
      expect(File.exist?('/tmp/groups/group_5ddcc1b181.txt')).to eq(true)
    end
    
    it 'should create sites dir' do
      @squid.reload_configuration(@model)
      expect(File.exist?('/tmp/sites')).to eq(true)
    end
    
    it 'should create sites files' do
      @squid.reload_configuration(@model)
      expect(File.exist?('/tmp/sites/sites_61dcba8056.txt')).to eq(true)
      expect(File.exist?('/tmp/sites/sites_5ddcc1b181.txt')).to eq(true)
    end
  
    it 'should call the squid reload script' do
      expect(@squid).to receive(:execute_command).once
      @squid.reload_configuration(@model)
    end
    
  end

end