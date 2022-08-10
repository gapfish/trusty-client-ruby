# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Data::JSONRPCNotificationRequest do
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
  subject { described_class.new(notification_body: request_payload) }

  describe '#new' do
    context 'with an invalid version' do
      before do
        request_payload['version'] = '1.0'
      end

      it 'fails with a version error' do
        expect { subject }.to raise_error(
          Trustly::Exception::JSONRPCVersionError,
          'JSON RPC Version 1.0 is not supported'
        )
      end
    end

    shared_examples_for 'valid request' do
      it 'has a uuid' do
        expect(subject.uuid).to eq(uuid)
      end

      it 'has a method' do
        expect(subject.method).to eq(method)
      end

      it 'has a signature' do
        expect(subject.signature).to eq('signature')
      end

      it 'has a version' do
        expect(subject.version).to eq('1.1')
      end
    end

    context 'with a json request payload' do
      let(:request_payload) do
        super().to_json
      end

      include_examples 'valid request'
    end

    context 'with a valid request payload' do
      include_examples 'valid request'
    end

    context 'with an invalid request payload' do
      let(:request_payload) do
        'invalid json'
      end

      it 'fails with a data error' do
        expect { subject }.to raise_error(
          Trustly::Exception::DataError
        )
      end
    end
  end
  describe '#data_at' do
    it 'fetches data field' do
      expect(subject.data_at('messageid')).to eq('453455465')
    end
  end
  describe '#attribute_at' do
    it 'fetches attribute field' do
      expect(subject.attribute_at('clearinghouse')).to eq('SWEDEN')
    end
  end
end
