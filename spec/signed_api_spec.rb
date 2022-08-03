# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Api::Signed do
  let(:basic_params) do
    {
      username: 'User',
      password: 'Password',
      private_pem: ENV['MERCHANT_PRIVATE_KEY'],
      public_pem: ENV['TRUSTLY_PUBLIC_KEY'],
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
          expect(subject.merchant_key.to_pem).to eq ENV['MERCHANT_PRIVATE_KEY']
        end
      end

      context 'when public key is not specified in the params' do
        let(:params) do
          basic_params.except(:public_key)
        end
        it 'uses default key' do
          expect(subject.trustly_key.to_pem).to eq ENV['TRUSTLY_PUBLIC_KEY']
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
  end

  describe 'rpc calls' do
    shared_examples_for 'rpc call' do |required_params|
      required_params.each do |param|
        context "with missing required param #{param}" do
          let(:modified_params) do
            params.except(param)
          end
          it 'raises data error' do
            expect do
              subject.public_send(method, params)
            end.to raise_error(
              Trustly::Exception::DataError,
              "Required data is missing: #{params}"
            )
          end
        end
        context 'with valid data' do
          context 'with a successful response' do
            before do
              expect(Trustly::Data::JSONRPCRequest).to receive(:new).
                with(method: method, data: data, attributes: attriubtes).
                and_return(double)
            end

            it 'makes a JSON RPC request and verifies its response' do
            end
          end
        end
      end
    end
  end
end
