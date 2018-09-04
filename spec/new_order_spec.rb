require 'dotenv/load'
require 'Faraday'
require 'Base64'
require 'openssl'
require 'byebug'
require 'awesome_print'
require 'json'

describe 'New Order Endpoint' do

  before(:all) do
    @base_url = 'https://api.sandbox.gemini.com'
    @new_order_url = "#{@base_url}/v1/order/new"
    @gemini_client = Faraday.new(url: @base_url) do |faraday|
      # faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end
    @TRADER_API_KEY = ENV['SANDBOX_TRADER_API_KEY']
    @API_SECRET = ENV['SANDBOX_TRADER_API_SECRET']
    @FUND_MANAGER_API_KEY = ENV['FUND_MGR_API_KEY']
    @FUND_MANAGER_API_SECRET = ENV['FUND_MGR_API_SECRET']
    @AUDITOR_API_KEY = ENV['AUDITOR_API_KEY']
    @AUDITOR_API_SECRET = ENV['AUDITOR_API_SECRET']
    @BOOLEANS = [ true, false ]
  end

  def is_valid_client_order_id?(id)
    return (id =~ /[:\-_\.#a-zA-Z0-9]{1,100}/) != nil
  end

  def generate_role_key(role)
    if role =~ /fund-manager/
      return [@FUND_MANAGER_API_KEY, @FUND_MANAGER_API_SECRET]
    elsif role =~ /auditor/
      return [@AUDITOR_API_KEY, @AUDITOR_API_SECRET]
    else
      raise "UNRECOGNIZED ROLE: #{role}"
    end
  end

  def generate_new_order_payload
    {
      "request": "/v1/order/new",
      "nonce": new_nonce,
      "client_order_id": rand(10**10).to_s,
      "symbol": 'btcusd',
      "amount": "0.003",
      "price": "622.13",
      "side": "buy",
      "type": "exchange limit",
    }
  end

  def new_nonce
    return (Time.now.to_f * 10_000).to_i.to_s
  end

  def sign(api_secret, payload)
    return OpenSSL::HMAC.hexdigest('SHA384', api_secret, payload)
  end

  def generate_new_order_headers(payload = nil, api_key = nil, api_secret = nil)
    api_key = @TRADER_API_KEY if api_key == nil
    api_secret = api_secret ? api_secret : @API_SECRET

    if (payload != nil)
      encoded_payload = payload
    else
      payload = generate_new_order_payload
      encoded_payload = Base64.strict_encode64(payload.to_json)
    end

    {
      'Content-Type': "text/plain",
      'Content-Length': "0",
      'X-GEMINI-APIKEY': api_key,
      'X-GEMINI-PAYLOAD': encoded_payload,
      'X-GEMINI-SIGNATURE': sign(api_secret, encoded_payload),
      'Cache-Control': "no-cache"
    }
  end

  describe 'Methods' do

    it 'should GET symbols' do
      response = @gemini_client.get("/v1/pubticker/btcusd")

      expect(response.status).to eql 200
    end

    context 'POST method' do

      it 'should accept a POST request with base64-encoded payload in header' do
        request_headers = generate_new_order_headers
        response = @gemini_client.post do |req|
          req.url @new_order_url,
          req.headers = request_headers
        end

        expect(response.status).to eql 200
      end

      it 'should not accept a POST request with plain text payload in header' do
        payload = generate_new_order_payload
        request_headers = generate_new_order_headers(payload.to_json)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(response.status).to eql 400
        expect(response.reason_phrase).to match /bad request/i
      end

      it 'should not accept a POST request with encoded payload in body of request' do
        payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers('')
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
          req.body = encoded_payload
        end

        expect(response.status).to eql 400
        expect(response.reason_phrase).to match /bad request/i
      end
    end

    context 'GET method' do

      xit 'should not accept a GET request method' do
        request_headers = generate_new_order_headers
        response = @gemini_client.get do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(response.status).to eql 405
        expect(response.reason_phrase).to match /bad request/i
      end
    end

    context 'PUT method' do

     it 'should not accept a PUT request method' do
        payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.put do |req|
          req.url @new_order_url
          req.headers = request_headers
          req.body = encoded_payload
        end

        expect(response.status).to eql 405
        expect(response.reason_phrase).to match /not allowed/i
      end
    end

    context 'DELETE method' do
      it 'should not accept a DELETE request method' do
        request_headers = generate_new_order_headers
        response = @gemini_client.delete do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(response.status).to eql 405
        expect(response.reason_phrase).to match /not allowed/i
      end
    end
  end

  describe 'Model' do

    it 'should return all expected response fields' do
      payload = generate_new_order_payload
      payload[:'options'] = ['maker-or-cancel']
      request_headers = generate_new_order_headers(Base64.strict_encode64(payload.to_json))
      response = @gemini_client.post do |req|
        req.url @new_order_url
        req.headers = request_headers
      end
      data = JSON.parse response.body

      expect(data).to have_key('order_id')
      expect(data['order_id'].class).to eql String
      expect(data).to have_key('id')
      expect(data['id'].class).to eql String
      expect(data['id']).to eql data['order_id']
      expect(data).to have_key('client_order_id')
      expect(data['client_order_id'].class).to eql String
      expect(data['client_order_id']).to eql payload[:'client_order_id']
      expect(data).to have_key('symbol')
      expect(data['symbol'].class).to eql String
      expect(data['symbol']).to eql payload[:'symbol']
      expect(data['exchange'].class).to eql String
      expect(data['exchange']).to match /gemini/i
      expect(data).to have_key('price')
      expect(data['price'].class).to eql String
      expect(data['price']).to eql payload[:'price']
      expect(data).to have_key('avg_execution_price')
      expect(data['avg_execution_price'].class).to eql String
      expect(data).to have_key('side')
      expect(data['side'].class).to eql String
      expect(data['side']).to eql payload[:'side']
      expect(data).to have_key('type')
      expect(data['type'].class).to eql String
      expect(data['type']).to eql payload[:'type']
      expect(data).to have_key('timestamp')
      expect(data['timestamp'].class).to eql String
      expect(data).to have_key('timestampms')
      expect(data['timestampms'].class).to eql Fixnum
      expect(data).to have_key('is_live')
      expect(@BOOLEANS).to include data['is_live'].class  # RUBY HAS DIFFERENT CLASSES FOR TRUE AND FALSE VALUES
      expect(data).to have_key('is_cancelled')
      expect(@BOOLEANS).to include data['is_cancelled'].class
      expect(data).to have_key('is_hidden')
      expect(@BOOLEANS).to include data['is_hidden'].class
      expect(data).to have_key('was_forced')
      expect(@BOOLEANS).to include data['was_forced'].class
      expect(data).to have_key('options')
      expect(data['options'].class).to eql Array
      expect(data['options']).to eql payload[:'options']
      expect(data).to have_key('executed_amount')
      expect(data['executed_amount'].class).to eql String
      expect(data).to have_key('remaining_amount')
      expect(data['remaining_amount'].class).to eql String
      expect(data).to have_key('original_amount')
      expect(data['original_amount'].class).to eql String
    end
  end

  describe 'Validations' do

    [
      :'request',
      :'nonce',
      :'symbol',
      :'amount',
      :'price',
      :'side',
      :'type'
    ].each do |required_field|
      it "should return 400 error without required field: #{required_field}" do
        payload = generate_new_order_payload
        payload.delete(required_field)
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(response.status).to eql 400
        expect(response.reason_phrase).to match /bad request/i
      end
    end

    [
      :'client_order_id',
    ].each do |optional_field|
      it "should accept a payload without optional field: #{optional_field}" do
        payload = generate_new_order_payload
        payload.delete(optional_field)
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(response.status).to eql 200
      end
    end

    context 'nonce field' do

      it 'should be unique with every request' do
        first_payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(first_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(response.status).to eql 200

        second_payload = generate_new_order_payload
        second_payload[:'nonce'] = first_payload[:'nonce']
        encoded_payload = Base64.strict_encode64(second_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 400
        expect(data['result']).to match /error/i
        expect(data['reason']).to match /InvalidNonce/i
        expect(data['message']).to match /Nonce \'\d+\' has not increased since your last call/i
      end

      xit 'should increment with every request' do
        first_payload = generate_new_order_payload
        encoded_payload = Base64.strict_encode64(first_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        first_response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(first_response.status).to eql 200

        second_payload = generate_new_order_payload
        second_payload[:nonce] = (first_payload[:nonce].to_i - 50).to_s
        encoded_payload = Base64.strict_encode64(second_payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        second_response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(second_response.status).to eql 400
      end
    end

    context 'client_order_id field' do

      it 'accepts a valid client order id' do
        payload = generate_new_order_payload
        payload[:client_order_id] = rand(100**100).to_s[0..99]
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end

        expect(response.status).to eql 200
      end

      it 'rejects an invalid client order id' do
        payload = generate_new_order_payload
        payload['client_order_id'] = rand(100**100).to_s[0..100]
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 400
        expect(data['result']).to match /error/i
        expect(data['reason']).to match /ClientOrderIdTooLong/i
        expect(data['message']).to match /client_order_id must be under 100 characters/i
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
          response = @gemini_client.post do |req|
            req.url @new_order_url
            req.headers = request_headers
          end
          data = JSON.parse response.body

          expect(response.status).to eql 200
          expect(data['symbol']).to eql valid_symbol
        end
      end

      it 'should reject an invalid symbol' do
        payload = generate_new_order_payload
        payload[:symbol] = 'neousd'
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 400
        expect(data['result']).to match /error/i
        expect(data['reason']).to match /InvalidSymbol/i
        expect(data['message']).to match /received bad symbol/i
      end
    end

    context 'amount field' do
      # enforces symbol minimum order size on a per symbol basis
      [
        {
          symbol: 'btcusd',
          minimum: '0.00001'
        },
        {
          symbol: 'ethusd',
          minimum: '0.001'
        },
        {
          symbol: 'ethbtc',
          minimum: '0.001'
        },
        {
          symbol: 'zecusd',
          minimum: '0.001'
        },
        {
          symbol: 'zecbtc',
          minimum: '0.001'
        },
        {
          symbol: 'zeceth',
          minimum: '0.001'
        }
      ].each do |currency|

        it "should accept minimum amount for #{currency[:symbol]}" do
          payload = generate_new_order_payload
          payload[:symbol] = currency[:symbol]
          payload[:'amount'] = currency[:minimum]
          encoded_payload = Base64.strict_encode64(payload.to_json)
          request_headers = generate_new_order_headers(encoded_payload)
          response = @gemini_client.post do |req|
            req.url @new_order_url
            req.headers = request_headers
          end
          data = JSON.parse response.body

          expect(response.status).to eql 200
          expect(data['original_amount']).to eql currency[:minimum].to_s
        end

        it "should reject amount below minimum for #{currency[:symbol]}" do
          payload = generate_new_order_payload
          payload[:symbol] = currency[:symbol]
          payload[:'amount'] = (currency[:minimum].to_f - currency[:minimum].to_f/10).to_s
          encoded_payload = Base64.strict_encode64(payload.to_json)
          request_headers = generate_new_order_headers(encoded_payload)
          response = @gemini_client.post do |req|
            req.url @new_order_url
            req.headers = request_headers
          end
          data = JSON.parse response.body

          expect(response.status).to eql 400
          expect(data['result']).to match /error/i
          expect(data['reason']).to match /InvalidQuantity/i
          expect(data['message']).to match /Invalid quantity for symbol/i
        end
      end
    end

    context 'type field' do

      it 'should support an exchange limit order type' do
        payload = generate_new_order_payload
        payload[:type] = 'exchange limit'
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 200
        expect(data['type']).to match /exchange limit/i
      end

      it 'should not support any other order type' do
        payload = generate_new_order_payload
        payload[:type] = 'good-until-cancelled'
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 400
        expect(data['result']).to match /error/i
        expect(data['reason']).to match /InvalidOrderType/i
        expect(data['message']).to match /Invalid order type for symbol/i
      end
    end

    context 'options field' do # order execution options
      # if no option provided, default is standard limit order
      # if more than one option is provided (or an unsupported option)
      # exchange will REJECT order

      it 'defaults to exchange limit order if none is provided' do
        request_headers = generate_new_order_headers
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 200
        expect(data['options'].length).to eql 0
        expect(data['type']).to eql 'exchange limit'
      end

      [
        'maker-or-cancel',
        'immediate-or-cancel',
        'auction-only',
        'indication-of-interest'
      ].each do |order_option|
        it "accepts valid order execution option: #{order_option}" do
          payload = generate_new_order_payload
          payload['options'] = [order_option]
          # MINIMUM for 'indication-of-interest' order option
          payload[:amount] = '10' if order_option == 'indication-of-interest'
          encoded_payload = Base64.strict_encode64(payload.to_json)
          request_headers = generate_new_order_headers(encoded_payload)
          response = @gemini_client.post do |req|
            req.url @new_order_url
            req.headers = request_headers
          end
          data = JSON.parse response.body

          expect(response.status).to eql 200
          expect(data['options'].length).to eql 1
          expect(data['options'].first).to eql order_option
        end
      end

      it 'rejects request with more than one order execution option' do
        payload = generate_new_order_payload
        payload['options'] = ['auction-only', 'maker-or-cancel']
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 400
        expect(data['result']).to match /error/i
        expect(data['reason']).to match /ConflictingOptions/i
        expect(data['message']).to match /A single order supports at most one of these options/i
      end

      it 'rejects request with an unsupported option' do
        payload = generate_new_order_payload
        payload[:options] = ['good-until-cancelled']
        encoded_payload = Base64.strict_encode64(payload.to_json)
        request_headers = generate_new_order_headers(encoded_payload)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 400
        expect(data['result']).to match /error/i
        expect(data['reason']).to match /UnsupportedOption/i
        expect(data['message']).to match /Option \"#{payload[:options].first}\" is not supported/i
      end
    end
  end

  describe 'Authorization' do

    it 'should allow trader role access' do
      request_headers = generate_new_order_headers
      response = @gemini_client.post do |req|
        req.url @new_order_url
        req.headers = request_headers
      end
      data = JSON.parse response.body

      expect(response.status).to eql 200
    end

    it 'should not allow any other role access' do
      [ 'fund-manager', 'auditor' ].each do |role|
        role_key, role_secret = generate_role_key(role)
        request_headers = generate_new_order_headers(nil, role_key)
        response = @gemini_client.post do |req|
          req.url @new_order_url
          req.headers = request_headers
        end
        data = JSON.parse response.body

        expect(response.status).to eql 400
        expect(data['result']).to match /error/i
        expect(data['reason']).to match /InvalidSignature/i
        expect(data['message']).to match /InvalidSignature/i
      end
    end
  end
end
