# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Utils::DataTransformer do
  describe '#deep_stringify_hash' do
    subject { described_class.deep_stringify_hash(params) }

    context 'with a hash containing symbolized keys' do
      let(:params) do
        {
          a: 10,
          b: [{ a: 10 }, :b, :c],
          c: { a: [], b: { a: 10 } }
        }
      end

      it do
        is_expected.to eq(
          'a' => 10,
          'b' => [{ 'a' => 10 }, :b, :c],
          'c' => { 'a' => [], 'b' => { 'a' => 10 } }
        )
      end
    end
  end
end
