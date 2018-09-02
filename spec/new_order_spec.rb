require 'dotenv/load'
require 'HTTParty'
require 'Base64'
require 'openssl'
require 'byebug'
require 'awesome_print'
require 'json'

describe 'New Order Endpoint' do

  before(:all) do
    base_url = 'https://api.sandbox.gemini.com'
    @new_order_url = "#{base_url}/v1/order/new"
    @TRADER_API_KEY = ENV['SANDBOX_TRADER_API_KEY']
    @API_SECRET = ENV['SANDBOX_TRADER_API_SECRET']
    @MANAGER_API_KEY = 'this-is-a-manager-key'
    @AUDITOR_API_KEY = 'read-only-auditor-key'
  end

  def is_valid_client_order_id?(id)
    return (id =~ /[:\-_\.#a-zA-Z0-9]{1,100}/) != nil
  end

  def generate_role_key(role)
    if role =~ /fund-manager/
      return @MANAGER_API_KEY
    elsif role =~ /auditor/
      return @AUDITOR_API_KEY
    else
      raise "UNRECOGNIZED ROLE: #{role}"
    end
  end

  def generate_new_order_payload
    {
      "request": "/v1/order/new",
      "nonce": new_nonce,
      "client_order_id": rand(10**10),
      "symbol": 'btcusd',
      "amount": "34.12",
      "price": "622.13",
      "side": [ "buy", "sell"].sample,
      "type": "exchange limit",
    }
  end

  def new_nonce
    return (Time.now.to_f * 10_000).to_i.to_s
  end

  def sign(payload)
    return OpenSSL::HMAC.hexdigest('SHA384', @API_SECRET, payload)
  end

  def generate_new_order_headers(payload = nil, api_key = nil)
    api_key = @TRADER_API_KEY if api_key == nil

    if (payload != nil)
      encoded_payload = payload
    else
      payload = generate_new_order_payload
      encoded_payload = Base64.strict_encode64(payload.to_json)
    end
byebug
    {
      'Content-Type': "text/plain",
      'Content-Length': "0",
      'X-GEMINI-APIKEY': api_key,
      'X-GEMINI-PAYLOAD': encoded_payload,
      'X-GEMINI-SIGNATURE': sign(encoded_payload),
      'Cache-Control': "no-cache"
    }
  end

  describe 'Methods' do

    context 'POST method' do

      it 'should accept a POST request with base64-encoded payload in header' do
        request_headers = generate_new_order_headers
        byebug
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers)
      byebug
        expect(response.code).to eql 200
      end

      it 'should not accept a POST request with plain text payload in header' do
        payload = generate_new_order_payload
        request_headers = generate_new_order_headers(payload.to_json)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 400 # BAD REQUEST
      end

      it 'should not accept a POST request with encoded payload in body of request' do
        payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => encoded_payload)

        expect(response.code).to eql 200
      end
    end

    context 'GET method' do

      it 'should not accept a GET request method' do
        request_headers = generate_new_order_headers
        response = HTTParty.get(@new_order_url,
                                :headers => request_headers)

        expect(response.code).to eql 405 # METHOD NOT ALLOWED
      end
    end

    context 'PUT method' do

     it 'should not accept a PUT request method' do
        payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.put(@new_order_url,
                                :headers => request_headers,
                                :body => encoded_payload)

        expect(response.code).to eql 405 # METHOD NOT ALLOWED
      end
    end

    context 'DELETE method' do
      it 'should not accept a DELETE request method' do
        request_headers = generate_new_order_headers
        response = HTTParty.delete(@new_order_url,
                                  :headers => request_headers)

        expect(response.code).to eql 405 # METHOD NOT ALLOWED
      end
    end
  end

  describe 'Model' do

    [
      'request',
      'nonce',
      'client_order_id',
      'symbol',
      'amount',
      'price',
      'side',
      'type'
    ].each do |required_field|
      it "should return 400 error without required field: #{required_field}" do
        payload = generate_new_order_payload
        payload.delete(required_field)
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 400
      end
    end

    it 'should return all expected response fields' do
      request_headers = generate_new_order_headers
      response = HTTParty.post(@new_order_url,
                              :headers => request_headers,
                              :body => nil)

      expect(response).to have_key('order_id')
      expect(response['order_id'].class).to eql String
      expect(response).to have_key('client_order_id')
      expect(response['client_order_id'].class).to eql String
      expect(response['client_order_id']).to eql payload['client_order_id']
      expect(response).to have_key('symbol')
      expect(response['symbol'].class).to eql String
      expect(response['symbol']).to eql payload['symbol']
      expect(response).to have_key('price')
      expect(response['price'].class).to eql String
      expect(response['price']).to eql payload['price']
      expect(response).to have_key('avg_execution_price')
      expect(response['avg_execution_price'].class).to eql String
      expect(response).to have_key('side')
      expect(response['side'].class).to eql String
      expect(response['side']).to eql payload['side']
      expect(response).to have_key('type')
      expect(response['type'].class).to eql String
      expect(response['type']).to eql payload['type']
      expect(response).to have_key('timestamp')
      expect(response['timestamp'].class).to eql String
      expect(response).to have_key('timestampms')
      expect(response['timestampms'].class).to eql Fixnum
      expect(response).to have_key('is_live')
      expect(response['is_live'].class).to eql Trueclass
      expect(response).to have_key('is_cancelled')
      expect(response['is_cancelled'].class).to eql Falseclass
      expect(response).to have_key('options')
      expect(response['options'].class).to eql Array
      expect(response['options']).to eql payload['options']
      expect(response).to have_key('executed_amount')
      expect(response['executed_amount'].class).to eql String
      expect(response).to have_key('remaining_amount')
      expect(response['remaining_amount'].class).to eql String
      expect(response).to have_key('original_amount')
      expect(response['original_amount'].class).to eql String
    end

    context 'nonce field' do
      # is unique with every request
      it 'should be unique with every request' do
        first_payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(first_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => encoded_payload)

        expect(response.code).to eql 200

        second_payload = generate_new_order_payload
        second_payload['nonce'] = first_payload['nonce']
        encoded_payload = Base64.strict_encode64(second_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => encoded_payload)

        expect(response.code).to eql 400
      end

      it 'should increment with every request' do
        first_payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(first_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => encoded_payload)

        expect(response.code).to eql 200

        second_payload = generate_new_order_payload
        second_payload['nonce'] = (first_payload['nonce'].to_i - 50).to_s
        encoded_payload = Base64.strict_encode64(second_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => encoded_payload)

        expect(response.code).to eql 400
      end
    end

    context 'client order id field' do

      it 'accepts a valid client order id' do
        payload = generate_new_order_payload
        payload['client_order_id'] = '%100d' % rand(100**100)
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 200
        expect(is_valid_client_order_id?(payload['client_order_id'])).to eql true
      end

      it 'rejects an invalid client order id' do
        payload = generate_new_order_payload
        payload['client_order_id'] = '%101d' % rand(100**100)
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 400
        expect(is_valid_client_order_id?(payload['client_order_id'])).to eql false
      end
    end

    context 'symbol field' do

      [
        'btcusd',
        'ethusd',
        'ethbtc',
        'zecusd',
        'zecbtc',
        'zeceth'
      ].each do |valid_symbol|
        it "should accept valid symbol: #{valid_symbol}" do
          payload = generate_new_order_payload
          payload['symbol'] = valid_symbol
          encoded_payload = Base64.strict_encode64(payload.to_json)
          request_headers = generate_new_order_headers(encoded_payload)
          response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

          expect(response.code).to eql 200
          expect(response['symbol']).to eql valid_symbol
        end
      end

      it 'should reject an invalid symbol' do
        payload = generate_new_order_payload
        payload['symbol'] = 'neousd'
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 400 # BAD REQUEST
      end
    end

    context 'amount field' do
      # enforces symbol minimum order size on a per symbol basis
      [
        {
          symbol: 'btcusd',
          minimum: 0.00001
        },
        {
          symbol: 'ethusd',
          minimum: 0.001
        },
        {
          symbol: 'ethbtc',
          minimum: 0.001
        },
        {
          symbol: 'zecusd',
          minimum: 0.001
        },
        {
          symbol: 'zecbtc',
          minimum: 0.001
        },
        {
          symbol: 'zeceth',
          minimum: 0.001
        }
      ].each do |currency|

        it "should accept minimum amount for #{currency[:symbol]}" do
          payload = generate_new_order_payload
          payload['amount'] = currency[:minimum]
          encoded_payload = Base64.strict_encode64(payload.to_json)
          request_headers = generate_new_order_headers(encoded_payload)
          response = HTTParty.post(@new_order_url,
                                  :headers => request_headers,
                                  :body => nil)

          expect(response.code).to eql 200
          expect(response['amount']).to eql currency[:minimum]
        end

        it "should reject amount below minimum for #{currency[:symbol]}" do
          payload = generate_new_order_payload
          payload['amount'] = (currency[:minimum].to_f - currency[:minimum].to_f/10).to_s
          encoded_payload = Base64.strict_encode64(payload.to_json)
          request_headers = generate_new_order_headers(encoded_payload)
          response = HTTParty.post(@new_order_url,
                                  :headers => request_headers,
                                  :body => nil)

          expect(response.code).to eql 400 # BAD REQUEST
        end
      end
    end

    context 'options field' do # order execution options
      # if no option provided, default is standard limit order
      # if more than one option is provided (or an unsupported option)
      # exchange will REJECT order

      it 'defaults to exchange limit order if none is provided' do
        request_headers = generate_new_order_headers
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 200
        expect(response['options'].length).to eql 1
        expect(response['options']).to include 'exchange limit'
      end

      [
        'exchange limit',
        'maker-or-cancel',
        'immediate-or-cancel',
        'auction-only',
        'indication-of-interest'
      ].each do |order_option|
        it "accepts valid order execution option: #{order_option}" do
          payload = generate_new_order_payload
          payload['options'] = [order_option]
          encoded_payload = Base64.strict_encode64(payload.to_json)
          request_headers = generate_new_order_headers(encoded_payload)
          response = HTTParty.post(@new_order_url,
                                  :headers => request_headers,
                                  :body => nil)

          expect(response.code).to eql 200
          expect(response['options'].length).to eql 1
          expect(response['options']).to include order_option
        end
      end

      it 'rejects request with more than one order execution option' do
        payload = generate_new_order_payload
        payload['options'] = ['limit', 'maker-or-cancel']
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 400 # BAD REQUEST
      end

      it 'rejects request with an unsupported option' do
        payload = generate_new_order_payload
        payload['options'] = ['good-until-cancelled']
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 400 # BAD REQUEST
      end
    end
  end

  describe 'Authorization' do

    it 'should allow trader access' do
      request_headers = generate_new_order_headers
      response = HTTParty.post(@new_order_url,
                              :headers => request_headers,
                              :body => nil)

    end

    it 'should not allow any other role access' do
      [ 'fund-manager', 'auditor' ].each do |role|
        role_specific_key = generate_role_key(role)
        request_headers = generate_new_order_headers(nil, role_specific_key)
        response = HTTParty.post(@new_order_url,
                                :headers => request_headers,
                                :body => nil)

        expect(response.code).to eql 403 # FORBIDDEN
      end
    end
  end
end