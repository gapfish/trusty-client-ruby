# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Data::JSONRPCNotificationResponse do
  let(:method) { 'Test' }
  let(:uuid) { '8bedfbd4-8181-38e1-f0be-f360171aefc6' }
  let(:request_payload) do
    {
      'method' => method,
      'params' => {
        'signature' => 'signature',
        'uuid' => uuid,
        'data' => {
          'notificationid' => '35673567',
          'messageid' => '453455465',
          'orderid' => '3473567567',
          'accountid' => '1234567890',
          'verified' => '1',
          'attributes' =>
              {
                'clearinghouse' => 'SWEDEN',
                'bank' => 'SEB',
                'descriptor' => '**** *084057',
                'lastdigits' => '084057'
              }
        }
      },
      'version' => '1.1'
    }
  end
  let(:request) do
    Trustly::Data::JSONRPCNotificationRequest.new(
      notification_body: request_payload
    )
  end
  let(:success) { true }

  shared_examples_for 'notification response' do |status|
    it 'matches the request\'s uuid' do
      expect(subject.uuid).to eq(uuid)
    end
    it 'matches the request\'s method' do
      expect(subject.method).to eq(method)
    end
    it 'has a correct version' do
      expect(subject.version).to eq('1.1')
    end
    it 'has response data' do
      expect(subject.data).to eq('status' => status)
    end
    it 'builds a correct payload' do
      expect(subject.payload).to eq(
        'version' => '1.1',
        'result' => {
          'method' => method,
          'uuid' => uuid,
          'data' => {
            'status' => status
          }
        }
      )
    end
  end
  describe '#new' do
    subject { described_class.new(request: request, success: success) }
    context 'with a successful request' do
      include_examples 'notification response', 'OK'
    end
    context 'with an error request' do
      let(:success) { false }
      include_examples 'notification response', 'FAILED'
    end
  end
  describe '#signature=' do
    subject { described_class.new(request: request, success: success) }
    let(:signature) { 'new signature' }

    context 'with a signature provided' do
      before do
        subject.signature = signature
      end

      it 'retrieves the signature with a getter' do
        expect(subject.signature).to eq(signature)
      end

      it 'properly sets up the signature in the payload' do
        expect(subject.payload['result']['signature']).to eq(signature)
      end
    end
  end
end
