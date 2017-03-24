require_relative '../app/config_fetcher'

describe ConfigFetcher do

  describe 'Full config fetch from broker' do

    before(:each) do
      @config_fetcher = ConfigFetcher.new(true, 'http://cf-proxy-broker.10.244.0.34.xip.io', 'admin', 'password')
      stub_request(:get, 'http://cf-proxy-broker.10.244.0.34.xip.io/fullconfig').
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic YWRtaW46cGFzc3dvcmQ=', 'User-Agent'=>'Faraday v0.11.0'}).
          to_return(:status => 200, :body => '{"some_key":"some_value"}', :headers => {})
    end

    it 'calls the broker' do
      config = @config_fetcher.model_from_broker
      expect(config['some_key']).to eq('some_value')
    end

  end

  describe 'No broker - empty config' do

    before(:each) do
      @config_fetcher = ConfigFetcher.new(false, '', '', '')
    end

    it 'does not call the broker - returns empty config instead' do
      config = @config_fetcher.model_from_broker
      expect(config).to be_empty
    end


  end

end
