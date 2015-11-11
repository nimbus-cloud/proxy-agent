
describe 'ProxyAgent' do

  include_context :rack_test
  
  describe 'Root URL' do
    before(:each) do
      stub_request(:get, 'http://admin:password@cf-proxy-broker.10.244.0.34.xip.io/fullconfig').
          to_return(:status => 200, :body => {}.to_json)

      get '/'
    end
      
    it 'should return return a 200' do
      expect(last_response.status).to eq(200)
    end
    
    it 'should return "Proxy Agent"' do
      expect(resp_hash['msg']).to eq('Proxy Agent')
    end
  end

end
