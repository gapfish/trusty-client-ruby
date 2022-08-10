# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Data::JSONRPCResponse do
  let(:uuid) { '8bedfbd4-8181-38e1-f0be-f360171aefc6' }
  let(:signature) { 'signature' }
  let(:method) { 'Test' }
  let(:data) do
    {
      'result' => '1',
      'orderid' => '1187741486'
    }
  end
  let(:payload) do
    {
      'version' => '1.1',
      'result' => {
        'signature' => signature,
        'method' => method,
        'data' => data,
        'uuid' => uuid
      }
    }
  end
  let(:status) { 200 }
  let(:phrase) { 'OK' }
  let(:response) do
    Faraday::Response.new(
      status: status,
      response_headers: { 'Content-Type': 'application/json' },
      response_body: payload,
      method: :post,
      reason_phrase: phrase
    )
  end
  subject { described_class.new(http_response: response) }
  describe '#new' do
    shared_examples_for 'parsed response' do |success|
      it 'has method' do
        expect(subject.method).to eq(method)
      end

      it 'has signature' do
        expect(subject.signature).to eq(signature)
      end

      it 'has UUID' do
        expect(subject.uuid).to eq(uuid)
      end

      it 'has data' do
        expect(subject.data).to eq(data)
      end

      if success
        it 'is marked as a success' do
          expect(subject.success?).to be_truthy
        end
        it 'is not marked as an error' do
          expect(subject.error?).to be_falsy
        end
        it 'does not have an error code' do
          expect(subject.error_code).to be_nil
        end
        it 'has an error message' do
          expect(subject.error_message).to be_nil
        end
      else
        it 'is marked as en error' do
          expect(subject.error?).to be_truthy
        end
        it 'is not marked as a success' do
          expect(subject.success?).to be_falsy
        end
        it 'has an error code' do
          expect(subject.error_code).to eq(error_code)
        end
        it 'has an error message' do
          expect(subject.error_message).to eq(error_message)
        end
      end
    end

    context 'with an invalid response payload' do
      before do
        payload.delete('result')
        payload['data'] = {}
      end

      it 'fails' do
        expect { subject }.to raise_error(
          Trustly::Exception::DataError,
          "No result or error in response #{payload}"
        )
      end
    end
    context 'with an invalid API version' do
      before do
        payload.merge!('version' => '1.0')
      end

      it 'fails' do
        expect { subject }.to raise_error(
          Trustly::Exception::JSONRPCVersionError,
          'JSON RPC Version is not supported'
        )
      end
    end
    context 'with a valid response' do
      include_examples 'parsed response', true
    end
    context 'with an error response' do
      let(:error_code) { 616 }
      let(:error_message) { 'ERROR_INVALID_CREDENTIALS' }
      let(:data) do
        {
          'code' => error_code,
          'message' => error_message
        }
      end
      let(:payload) do
        {
          'version' => '1.1',
          'error' => {
            'name' => 'JSONRPCError',
            'code' => error_code,
            'message' => error_message,
            'error' => {
              'signature' => signature,
              'uuid' => uuid,
              'method' => method,
              'data' => data
            }
          }
        }
      end
      include_examples 'parsed response', false
    end
  end
  describe '#data_at' do
    context 'with response data' do
      it 'returns data for a specific key' do
        expect(subject.data_at('orderid')).to eq('1187741486')
      end
    end
    context 'without data' do
      before do
        payload['result'].delete('data')
      end

      it 'returns nil' do
        expect(subject.data_at('orderid')).to be_nil
      end
    end
  end
end
