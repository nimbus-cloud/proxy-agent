
describe 'ProxyAgent' do

  include_context :rack_test

  before(:each) do
    stub_request(:get, 'http://cf-proxy-broker.10.244.0.34.xip.io/fullconfig').
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic YWRtaW46cGFzc3dvcmQ=', 'User-Agent'=>'Faraday v0.11.0'}).
        to_return(:status => 200, :body => '{}', :headers => {})
  end


  describe 'Root URL' do
    before(:each) do
      get '/'
    end
      
    it 'should return return a 200' do
      expect(last_response.status).to eq(200)
    end
    
    it 'should return "Proxy Agent"' do
      expect(resp_hash['msg']).to eq('Proxy Agent')
    end
  end

  describe '/newuser' do
    it 'works' do
      put '/newuser', {:username => 'dave', :password => 'dave1234'}.to_json

      expect(last_response.status).to eq(200)
      expect(resp_hash).to eq({})
    end
  end

  describe '/deleteuser' do
    it 'works' do
      put '/newuser', {:username => 'dave', :password => 'dave1234'}.to_json

      expect(last_response.status).to eq(200)
      expect(resp_hash).to eq({})
    end
  end

  describe '/applyschema' do
    it 'works' do
      put '/newuser', {:username => 'dave', :password => 'dave1234'}.to_json

      expect(last_response.status).to eq(200)
      expect(resp_hash).to eq({})

      post '/applyschema', {:username => 'dave', :allow_rules => []}.to_json

      expect(last_response.status).to eq(200)
      expect(resp_hash).to eq({})
    end
  end

end
