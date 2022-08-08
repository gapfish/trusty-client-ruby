# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Data::JSONRPCRequest do
  describe '#new' do
    subject { described_class.new(**params) }
    let(:method) { 'Test' }
    let(:data) { { 'A' => 1 } }
    let(:attributes) { { 'B' => 2 } }
    let(:uuid) { SecureRandom.uuid }
    let(:signature) { 'signature' }

    shared_examples_for 'successful initialization' do
      it 'has method' do
        expect(subject.payload).to include({
                                             'method' => method
                                           })
      end
      it 'has version' do
        expect(subject.payload).to include({
                                             'version' => 1.1
                                           })
      end
      it 'initializes payload' do
        expect(subject.payload).to include({
                                             'params' => a_hash_including({
                                                                            'Data' => {
                                                                              'Attributes' => attributes
                                                                            }.merge(data)
                                                                          })
                                           })
      end
      it 'initializes attributes' do
        expect(subject.attributes).to eq({ 'B' => 2 })
      end
      it 'initializes data' do
        expect(subject.data).to eq({ 'A' => 1, 'Attributes' => attributes })
      end
      it 'reads data' do
        expect(subject.data_at('A')).to eq(1)
      end
      it 'reads attributes' do
        expect(subject.attribute_at('B')).to eq(2)
      end
    end

    context 'with data and attributes' do
      context 'with invalid data' do
        let(:params) do
          {
            data: [1, 2, 3],
            attributes: { 'Data' => 'test' }
          }
        end
        it 'raises TypeError' do
          expect { subject }.to raise_error(
            TypeError,
            'Data must be a Hash if attributes are provided'
          )
        end
      end
      context 'with valid data' do
        context 'with cleanup' do
          let(:params) do
            {
              data: data,
              attributes: attributes
            }
          end
          let(:data) do
            {
              'A' => 1,
              'EmptyArray' => [],
              'EmptyValue' => nil,
              'EmptyNestedHash' => { 'EmptyArray' => [], 'EmptyValue' => nil }
            }
          end
          let(:attributes) do
            {
              'B' => 2,
              'EmptyNestedHash' => { 'EmptyArray' => [], 'EmptyValue' => nil }
            }
          end

          it 'cleans up data' do
            expect(subject.data).to eq('A' => 1, 'Attributes' => { 'B' => 2 })
          end
        end
        context 'without cleanup' do
          let(:params) do
            {
              data: data,
              attributes: attributes,
              method: method
            }
          end
          include_examples 'successful initialization'
        end
      end
    end
    context 'with attributes only' do
      let(:params) do
        {
          attributes: attributes
        }
      end

      it 'still initializes data' do
        expect(subject.data).to eq('Attributes' => attributes)
      end

      it 'initializes attributes' do
        expect(subject.attributes).to eq(attributes)
      end
    end
    context 'with data only' do
      let(:params) do
        {
          data: data
        }
      end

      it 'initializes data' do
        expect(subject.data).to eq('A' => 1)
      end

      it 'does not initialize attributes' do
        expect(subject.attributes).to be_nil
      end
    end
    context 'without data and attributes' do
      let(:params) do
        {}
      end

      it 'does not initialize data' do
        expect(subject.data).to be_nil
      end

      it 'initializes params' do
        expect(subject.params).to eq({})
      end
    end
    context 'with payload' do
      let(:params) do
        {
          payload: {
            'method' => method,
            'params' => {
              'UUID' => uuid,
              'Signature' => signature,
              'Data' => {
                'Attributes' => attributes
              }.merge(data)
            }
          }
        }
      end
      include_examples 'successful initialization'
      it 'initializes uuid' do
        expect(subject.uuid).to eq(uuid)
      end
      it 'initializes signature' do
        expect(subject.signature).to eq(signature)
      end
    end
  end
  describe '#setters' do
    subject do
      described_class.new(payload: payload)
    end
    let(:payload) do
      {
        'method' => 'Test',
        'params' => {
          'Data' => {
            'A' => 1,
            'Attributes' => {
              'B' => 2
            }
          }
        }
      }
    end

    describe '#update_data_at' do
      it 'updates data at a specific key' do
        subject.update_data_at('A', 10)
        expect(subject.data).to include({ 'A' => 10 })
      end

      it 'inserts new data at a specific key' do
        subject.update_data_at('C', 30)
        expect(subject.data).to include({ 'A' => 1, 'C' => 30 })
      end
    end

    describe '#update_attribute_at' do
      it 'updates attribute at a specific key' do
        subject.update_attribute_at('B', 10)
        expect(subject.attributes).to include({ 'B' => 10 })
      end

      it 'inserts a new attribute at a specific key' do
        subject.update_attribute_at('C', 30)
        expect(subject.attributes).to include({ 'B' => 2, 'C' => 30 })
      end
    end

    describe '#signature=' do
      it 'updates signature' do
        subject.signature = 'signature'
        expect(subject.params).to include('Signature' => 'signature')
      end
    end

    describe '#uuid=' do
      it 'updates signature' do
        uuid = SecureRandom.uuid
        subject.uuid = uuid
        expect(subject.params).to include('UUID' => uuid)
      end
    end

    describe '#method=' do
      it 'updates signature' do
        subject.method = 'OtherTest'
        expect(subject.payload).to include('method' => 'OtherTest')
      end
    end
  end
end
