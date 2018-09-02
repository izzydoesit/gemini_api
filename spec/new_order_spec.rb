
describe 'New Orders' do
  include HTTParty

  before(:all) do
    @base_url = 'https://api.gemini.com/v1/order/new'
    @API_KEY = 'ucSCx8mI7qpkH4XFecRX'
    @API_SECRET = 'CvrG1JJEeUw3X6b3EzVAcUfM59J'
  end

  describe 'Methods' do

    context 'POST method' do

      it 'should accept a request with base64-encoded payload in header' do

      end

      it 'should not accept a request with plain text payload in header' do

      end

      it 'should not accept a request with payload in body of request' do

      end
    end


    it 'should not accept a GET request method' do

    end

    it 'should not accept a PUT request method' do

    end

    it 'should not accept a PATCH request method' do

    end

    it 'should not accept a DELETE request method' do


    end
  end

  describe 'Model' do

    it 'should require minimal required fields' do
    #   {
    #     "request": "/v1/order/new",
    #     "nonce": <nonce>,
    #     "client_order_id": "20150102-4738721",
    #     "symbol": "btcusd",
    #     "amount": "34.12",
    #     "price": "622.13",
    #     "side": "buy",
    #     "type": "exchange limit",
    # }
    end

    it 'should accept all optional fields' do
    #   {
    #     "request": "/v1/order/new",
    #     "nonce": <nonce>,
    #     "client_order_id": "20150102-4738721",
    #     "symbol": "btcusd",
    #     "amount": "34.12",
    #     "price": "622.13",
    #     "side": "buy",
    #     "type": "exchange limit",
    #     "options": ["maker-or-cancel"]
    # }
    end

    it 'should return all expected response fields' do


      # RESPONSE EX:
      # {
      #     "order_id": "22333",
      #     "client_order_id": "20150102-4738721",
      #     "symbol": "btcusd",
      #     "price": "34.23",
      #     "avg_execution_price": "34.24",
      #     "side": "buy",
      #     "type": "exchange limit",
      #     "timestamp": "128938491",
      #     "timestampms": 128938491234,
      #     "is_live": true,
      #     "is_cancelled": false,
      #     "options": ["maker-or-cancel"],
      #     "executed_amount": "12.11",
      #     "remaining_amount": "16.22",
      #     "original_amount": "28.33"
      # }
    end

    context 'nonce field' do

    end

    context 'symbol field' do

    end

    context 'options field' do # order execution options
      # if no option provided, default is standard limit order
      # if more than one option is provided (or an unsupported option)
      # exchange will REJECT order
      #
      # maker-or-cancel
      # immediate-or-cancel
      # auction-only
      # indication-of-interest
    end
  end

  describe 'Authorization' do

    it 'should allow admin access' do

    end

    it 'should allow all other roles access' do

    end
  end
end