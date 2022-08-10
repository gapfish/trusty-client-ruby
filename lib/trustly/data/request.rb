# frozen_string_literal: true

module Trustly
  module Data
    class Request < Base
      attr_accessor :method

      def initialize(**options)
        super
        if (new_payload = options[:payload])
          vacuumed_payload = vacuum(new_payload)
          self.payload = stringify_hash(vacuumed_payload)
        end
        self.method = options[:method] || payload['method']
      end
    end
  end
end
