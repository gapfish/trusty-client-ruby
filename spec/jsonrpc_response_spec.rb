# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Data::JSONRPCResponse do
  describe '#new' do
    subject { described_class.new(http_response: response) }
    let(:payload) do
      {
        'version' => '1.1',
        'result' => {
          'signature' => 'signature',
          'method' => 'Test',
          'data' => {
            'result' => '1',
            'orderid' => '1187741486'
          },
          'uuid' => '8bedfbd4-8181-38e1-f0be-f360171aefc6'
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
  end
end
