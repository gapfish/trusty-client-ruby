# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Api::Signed do
  let(:basic_params) do
    {
      username: 'User',
      password: 'Password',
      private_pem: ENV.fetch('MERCHANT_PRIVATE_KEY', nil),
      public_pem: ENV.fetch('TRUSTLY_PUBLIC_KEY', nil),
      host: 'test.trustly.com'
    }
  end
  describe '#new' do
    context 'successful initialization' do
      subject { described_class.new(**params) }

      context 'when private key is not specified in the params' do
        let(:params) do
          basic_params.except(:private_pem)
        end
        it 'uses default key' do
          expect(subject.merchant_key.to_pem).to eq ENV.fetch('MERCHANT_PRIVATE_KEY', nil)
        end
      end

      context 'when public key is not specified in the params' do
        let(:params) do
          basic_params.except(:public_key)
        end
        it 'uses default key' do
          expect(subject.trustly_key.to_pem).to eq ENV.fetch('TRUSTLY_PUBLIC_KEY', nil)
        end
      end

      context 'when host is not specified in the params' do
        let(:params) do
          basic_params.except(:host)
        end
        it 'uses default key' do
          expect(subject.api_host).to eq 'test.trustly.com'
        end
      end

      context 'with valid params' do
        let(:params) do
          basic_params.merge(
            host: 'prod.trustly.com', port: 80, is_https: false
          )
        end
        it 'initializes correctly' do
          expect(subject.api_host).to eq 'prod.trustly.com'
          expect(subject.api_port).to eq 80
          expect(subject.api_is_https).to eq false
          expect(subject.api_username).to eq 'User'
          expect(subject.api_password).to eq 'Password'
        end
      end
    end

    context 'initialization errors' do
      shared_examples_for 'incorrect configuration' do
        it 'fails' do
          expect do
            described_class.new(**params)
          end.to raise_error(
            Trustly::Exception::ConfigurationError, message
          )
        end
      end
      context 'with username not specified' do
        let(:params) do
          basic_params.except(:username)
        end
        let(:message) do
          'Username not specified'
        end
        include_examples 'incorrect configuration'
      end
      context 'with password not specified' do
        let(:params) do
          basic_params.except(:password)
        end
        let(:message) do
          'Password not specified'
        end
        include_examples 'incorrect configuration'
      end
      context 'when private key is invalid' do
        let(:params) { basic_params }
        before do
          expect(OpenSSL::PKey::RSA).to receive(:new)
            .with(basic_params[:public_pem]).and_call_original
          expect(OpenSSL::PKey::RSA).to receive(:new)
            .with(basic_params[:private_pem]).and_raise(OpenSSL::PKey::RSAError)
        end
        let(:message) do
          'Merchant private key not specified'
        end
        include_examples 'incorrect configuration'
      end
      context 'with private key is nil' do
        let(:params) do
          basic_params.merge(private_pem: nil)
        end
        let(:message) do
          'Merchant private key not specified'
        end
        include_examples 'incorrect configuration'
      end
      context 'with public key is nil' do
        let(:params) do
          basic_params.merge(public_pem: nil)
        end
        let(:message) do
          'Trustly public key not specified'
        end
        include_examples 'incorrect configuration'
      end
      context 'with public key having incorrect value' do
        let(:params) do
          basic_params.merge(public_pem: 'test')
        end
        let(:message) do
          'Trustly public key not specified'
        end
        include_examples 'incorrect configuration'
      end
      context 'with multiple errors' do
        let(:params) do
          basic_params.except(:username).merge(host: nil)
        end
        let(:message) do
          'Api host not specified; Username not specified'
        end
        include_examples 'incorrect configuration'
      end
    end
  end

  describe '#verify_signed_response' do
    subject { described_class.new(**params).verify_signed_response(response) }
    let(:params) { basic_params }
    let(:payload) do
      path = File.expand_path('./data/account_payout.json', __dir__)
      json = File.read(path)
      JSON.parse(json)
    end
    let(:http_response) do
      Faraday::Response.new(
        status: 200,
        response_headers: { 'Content-Type': 'application/json' },
        response_body: payload,
        method: :post,
        reason_phrase: 'OK'
      )
    end
    let(:response) do
      Trustly::Data::JSONRPCResponse.new(http_response: http_response)
    end
    context 'with valid body and signature' do
      it { is_expected.to be_truthy }
    end

    context 'with the data in body not matching the signature' do
      before do
        payload['result']['method'] = 'AccountPayouts'
      end

      it { is_expected.to be_falsy }
    end
  end

  describe 'rpc calls' do
    subject { described_class.new(**basic_params) }
    shared_examples_for 'rpc call' do |required_params|
      required_params.each do |param|
        context "with missing required param #{param}" do
          let(:modified_params) do
            params.except(param)
          end
          it 'raises data error' do
            expect do
              subject.public_send(rpc_call, **modified_params)
            end.to raise_error(
              Trustly::Exception::DataError,
              "Required data is missing: #{param}"
            )
          end
        end
      end
      context 'with valid data' do
        let(:request) do
          instance_double(Trustly::Data::JSONRPCRequest)
        end
        let(:serial_data) do
          "#{method}#{uuid}ArrayKey123KeyValue"
        end
        let(:signature) do
          Base64.encode64('signature').chop
        end
        let(:connection) do
          instance_double(Faraday::Connection)
        end
        let(:body) do
          '{"Key":"Value"}'
        end
        let(:http_response) do
          instance_double(Faraday::Response)
        end
        let(:response) do
          instance_double(Trustly::Data::JSONRPCResponse)
        end
        let(:uuid) do
          '8bedfbd4-8181-38e1-f0be-f360171aefc6'
        end
        let(:response_uuid) { uuid }
        let(:response_body) { { 'key' => 'value' } }
        let(:response_signature) { signature }
        let(:serial_response_data) do
          "#{method}#{response_uuid}keyvalue"
        end

        before do
          expect(Trustly::Data::JSONRPCRequest).to receive(:new)
            .with(method: method, data: data, attributes: attributes)
            .and_return(request)
          expect(SecureRandom).to receive(:uuid).and_return(uuid)
          expect(request).to receive(:uuid=).with(uuid)
          expect(request).to receive(:signature=).with(signature)
          expect(request).to receive(:uuid).and_return(nil)
          expect(request).to receive(:uuid).at_least(:once).and_return(uuid)
          expect(request).to receive(:method).at_least(:once).and_return(method)
          expect(request).to receive(:data).and_return('Key' => 'Value', 'ArrayKey' => [1, 2, 3])
          expect(request).to receive(:update_data_at).with('Username', 'User')
          expect(request).to receive(:update_data_at).with('Password', 'Password')
          expect(subject.merchant_key).to receive(:sign).with(
            instance_of(OpenSSL::Digest), serial_data
          ).and_return('signature')
          expect(request).to receive(:to_json).and_return(body)
          expect(Faraday).to receive(:new).with('https://test.trustly.com')
                                          .and_return(connection)
        end
        context 'with a successful response' do
          before do
            expect(connection).to receive(:post).with(
              '/api/1', body, { 'Content-Type' => 'application/json' }
            ).and_return(http_response)
            expect(Trustly::Data::JSONRPCResponse).to receive(:new)
              .with(http_response: http_response).and_return(response)
            expect(response).to receive(:uuid).at_least(:once)
                                              .and_return(response_uuid)
            expect(response).to receive(:data).at_least(:once)
                                              .and_return(response_body)
            expect(response).to receive(:method).at_least(:once)
                                                .and_return(method)
            expect(response).to receive(:signature)
              .and_return(response_signature)
            expect(subject.trustly_key).to receive_message_chain(
              :public_key, :verify
            ).with(
              instance_of(OpenSSL::Digest), 'signature', serial_response_data
            ).and_return(true)
          end
          it 'makes a JSON RPC request and verifies its response' do
            expect(subject.public_send(rpc_call, **params)).to eq(response)
          end
        end
        context 'with a failed response' do
          context 'with a faraday error' do
            let(:error_response) { nil }

            before do
              exception = error_klass.new(
                StandardError.new(error_message), error_response
              )
              expect(connection).to receive(:post).with(
                '/api/1', body, { 'Content-Type' => 'application/json' }
              ).and_raise(exception)
            end

            shared_examples_for 'faraday error' do
              it 'fails with an expected trustly error' do
                expect { subject.public_send(rpc_call, **params) }.to raise_error(
                  expected_error, expected_error_message
                )
              end
            end

            context 'with a client error' do
              let(:error_klass) { Faraday::ClientError }
              let(:expected_error) { Trustly::Exception::DataError }
              let(:error_response) { { status: 400, body: '{"error":"failed"}' } }
              let(:error_message) { 'Bad request' }
              let(:expected_error_message) do
                "Bad request -> 400: {\"error\":\"failed\"} - #{method}, {\"Key\":\"Value\"}"
              end
              include_examples 'faraday error'
            end

            context 'with a server error' do
              let(:error_klass) { Faraday::ServerError }
              let(:expected_error) { Trustly::Exception::ConnectionError }
              let(:error_message) { 'Server error' }
              let(:expected_error_message) do
                'Server error'
              end
              include_examples 'faraday error'
            end

            context 'with a connection error' do
              let(:error_klass) { Faraday::ConnectionFailed }
              let(:expected_error) { Trustly::Exception::ConnectionError }
              let(:error_message) { 'Connection error' }
              let(:expected_error_message) do
                'Connection error'
              end
              include_examples 'faraday error'
            end

            context 'with an ssl error' do
              let(:error_klass) { Faraday::SSLError }
              let(:expected_error) { Trustly::Exception::ConnectionError }
              let(:error_message) { 'SSL error' }
              let(:expected_error_message) do
                'SSL error'
              end
              include_examples 'faraday error'
            end

            context 'with a parsing error' do
              let(:error_klass) { Faraday::ParsingError }
              let(:expected_error) { Trustly::Exception::DataError }
              let(:error_message) { 'JSON error' }
              let(:error_response) { { status: 200, body: 'abcd' } }
              let(:expected_error_message) do
                "JSON error -> 200: abcd - #{method}, {\"Key\":\"Value\"}"
              end
              include_examples 'faraday error'
            end
          end

          context 'with an invalid response payload' do
            before do
              expect(connection).to receive(:post).with(
                '/api/1', body, { 'Content-Type' => 'application/json' }
              ).and_return(http_response)
              expect(Trustly::Data::JSONRPCResponse).to receive(:new)
                .with(http_response: http_response).and_return(response)
              expect(response).to receive(:uuid).at_least(:once)
                                                .and_return(response_uuid)
            end

            context 'with an incorrect uuid' do
              let(:response_uuid) do
                '8bedfbd4-8181-38e1-f0be-f360171aef6c'
              end

              it 'fails with a uuid mismatch error' do
                expect { subject.public_send(rpc_call, **params) }.to raise_error(
                  Trustly::Exception::DataError,
                  'Incoming response is not related to the request. UUID mismatch.'
                )
              end
            end

            context 'with an incorrect signature' do
              before do
                expect(response).to receive(:data).and_return(response_body)
                expect(response).to receive(:method).and_return(method)
                expect(response).to receive(:signature)
                  .and_return(response_signature)
                expect(subject.trustly_key).to receive_message_chain(
                  :public_key, :verify
                ).with(
                  instance_of(OpenSSL::Digest), 'signature', serial_response_data
                ).and_return(false)
              end

              it 'fails with a signature error' do
                expect { subject.public_send(rpc_call, **params) }.to raise_error(
                  Trustly::Exception::SignatureError,
                  'Incoming message signature is not valid'
                )
              end
            end
          end
        end
      end
    end

    describe '#refund' do
      let(:method) { 'Refund' }
      let(:rpc_call) { :refund }
      let(:data) do
        {
          'OrderId' => '12345',
          'Amount' => 100,
          'Currency' => 'EUR'
        }
      end
      let(:attributes) do
        {
          'ExternalReference' => { 'Value' => 'Test' }
        }
      end
      let(:params) do
        data.merge(attributes)
      end
      include_examples 'rpc call', %w[OrderId Amount Currency]
    end

    describe '#void' do
      let(:method) { 'Void' }
      let(:rpc_call) { :void }
      let(:data) do
        {
          'OrderId' => '12345'
        }
      end
      let(:attributes) do
        nil
      end
      let(:params) do
        data
      end
      include_examples 'rpc call', %w[OrderId]
    end

    describe '#get_withdrawals' do
      let(:method) { 'GetWithdrawals' }
      let(:rpc_call) { :get_withdrawals }
      let(:data) do
        {
          'OrderId' => '12345'
        }
      end
      let(:attributes) do
        nil
      end
      let(:params) do
        data
      end
      include_examples 'rpc call', %w[OrderId]
    end

    describe '#refund' do
      let(:method) { 'Refund' }
      let(:rpc_call) { :refund }
      let(:data) do
        {
          'OrderId' => '12345',
          'Amount' => '100.00',
          'Currency' => 'EUR'
        }
      end
      let(:attributes) do
        {
          'ExternalReference' => { 'Value' => 'Test' }
        }
      end
      let(:params) do
        data.merge(attributes)
      end
      include_examples 'rpc call', %w[OrderId Amount Currency]
    end

    describe '#deposit' do
      let(:method) { 'Deposit' }
      let(:rpc_call) { :deposit }
      let(:data) do
        {
          'NotificationURL' => 'https://example.com/notify',
          'EndUserID' => '123',
          'MessageID' => '123'
        }
      end
      let(:attributes) do
        {
          'Locale' => 'en-gb',
          'Country' => 'NL',
          'Currency' => 'EUR',
          'SuccessURL' => 'https://example.com/success',
          'FailURL' => 'https://example.com/fail',
          'Amount' => '200.00',
          'Firstname' => 'First',
          'Lastname' => 'Last',
          'ShopperStatement' => 'Trustly.com',
          'MobilePhone' => '+49 151 88888888'
        }
      end
      let(:params) do
        data.merge(attributes)
      end
      include_examples 'rpc call', %w[
        Locale Country Currency SuccessURL FailURL NotificationURL Amount
        EndUserID MessageID Firstname Lastname ShopperStatement
      ]
    end

    describe '#select_account' do
      let(:method) { 'SelectAccount' }
      let(:rpc_call) { :select_account }
      let(:data) do
        {
          'NotificationURL' => 'https://example.com/notify',
          'EndUserID' => '123',
          'MessageID' => '123'
        }
      end
      let(:extra_attributes) do
        attributes.merge('WillBeRemoved' => true)
      end
      let(:attributes) do
        {
          'Locale' => 'en-gb',
          'Country' => 'NL',
          'SuccessURL' => 'https://example.com/success',
          'FailURL' => 'https://example.com/fail',
          'Firstname' => 'First',
          'Lastname' => 'Last',
          'Email' => 'test@mail.com'
        }
      end
      let(:params) do
        data.merge(extra_attributes)
      end
      include_examples 'rpc call', %w[
        Locale Country SuccessURL FailURL NotificationURL EndUserID MessageID
        Firstname Lastname
      ]
    end

    describe '#register_account' do
      let(:method) { 'RegisterAccount' }
      let(:rpc_call) { :register_account }
      let(:data) do
        {
          'EndUserID' => '123',
          'ClearingHouse' => 'SWEDEN',
          'BankNumber' => '6612',
          'AccountNumber' => '69706212',
          'Firstname' => 'First',
          'Lastname' => 'Last'
        }
      end
      let(:attributes) do
        {
          'DateOfBirth' => '15/08/1993',
          'MobilePhone' => '+49 151 88888888'
        }
      end
      let(:params) do
        data.merge(attributes)
      end
      include_examples 'rpc call', %w[
        EndUserID ClearingHouse BankNumber AccountNumber Firstname Lastname
      ]
    end

    describe '#account_payout' do
      let(:method) { 'AccountPayout' }
      let(:rpc_call) { :account_payout }
      let(:data) do
        {
          'NotificationURL' => 'https://example.com/notify',
          'EndUserID' => '123',
          'MessageID' => '123',
          'AccountID' => '123',
          'Amount' => '500.00',
          'Currency' => 'EUR'
        }
      end
      let(:attributes) do
        {
          'ShopperStatement' => 'Trustly.com'
        }
      end
      let(:params) do
        data.merge(attributes)
      end
      include_examples 'rpc call', %w[
        NotificationURL AccountID EndUserID MessageID Amount Currency
        ShopperStatement
      ]
    end
  end
  describe '#notification_response' do
    subject do
      described_class.new(**basic_params)
    end
    context 'with a request' do
      let(:success) { true }
      let(:uuid) { '123' }
      let(:method) { 'Test' }
      let(:data) { { 'Key' => 'Value' } }
      let(:serial_data) { 'Test123KeyValue' }
      let(:signature) { Base64.encode64('signature').chop }
      let(:request) { instance_double(Trustly::Data::JSONRPCNotificationRequest) }
      let(:response) { instance_double(Trustly::Data::JSONRPCNotificationResponse) }

      before do
        expect(Trustly::Data::JSONRPCNotificationResponse).to receive(:new)
          .with(request: request, success: success).and_return(response)
        expect(response).to receive(:uuid).and_return(uuid)
        expect(response).to receive(:method).and_return(method)
        expect(response).to receive(:data).and_return(data)
        expect(subject.merchant_key).to receive(:sign)
          .with(instance_of(OpenSSL::Digest), serial_data)
          .and_return('signature')
        expect(response).to receive(:signature=).with(signature)
      end

      it 'returns a response' do
        result = subject
                 .notification_response(request, success: success)
        expect(result).to eq(response)
      end
    end
  end
end
