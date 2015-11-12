
describe 'ProxyAgent' do

  include_context :rack_test

  before(:each) do
    stub_request(:get, 'http://admin:password@cf-proxy-broker.10.244.0.34.xip.io/fullconfig').
        to_return(:status => 200, :body => {}.to_json)
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
      put '/newuser/dave/dave1234'

      expect(last_response.status).to eq(200)
      expect(resp_hash).to eq({})
    end
  end

  describe '/deleteuser' do
    it 'works' do
      put '/newuser/dave/dave1234'

      expect(last_response.status).to eq(200)
      expect(resp_hash).to eq({})
    end
  end

  describe '/applyschema' do
    it 'works' do
      put '/newuser/dave/dave1234'
      post '/applyschema', {:username => 'dave', :allow_rules => []}.to_json

      expect(last_response.status).to eq(200)
      expect(resp_hash).to eq({})
    end
  end

end
