# frozen_string_literal: true

module Trustly
  module Data
    class Base
      attr_accessor :payload

      def initialize(**_options)
        self.payload = {}
      end

      def to_json(*_args)
        payload.to_json
      end
    end
  end
end
