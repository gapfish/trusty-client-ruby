# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trustly::Utils::DataCleaner do
  describe '#vacuum' do
    subject { described_class.vacuum(params) }

    context 'with a hash containing empty values and hollow arrays' do
      let(:params) do
        {
          a: 10,
          b: [],
          c: { a: nil },
          e: { a: [] },
          f: { a: { a: [] }, b: 10 }
        }
      end

      it { is_expected.to eq(a: 10, f: { b: 10 }) }
    end
  end
end
