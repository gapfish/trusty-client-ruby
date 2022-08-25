# frozen_string_literal: true

module Trustly
  module Data
    class JSONRPCResponse < Response
      VERSION_ERROR = 'JSON RPC Version is not supported'

      def initialize(**options)
        super
        version = payload['version']
        raise Trustly::Exception::JSONRPCVersionError, VERSION_ERROR if version != '1.1'
      end

      def data_at(name)
        return if data.nil?

        data[name]
      end
    end
  end
end
