# frozen_string_literal: true

module Trustly
  module Data
    class JSONRPCNotificationRequest < Request
      def initialize(**options)
        super(payload: notification_body(options[:notification_body]))
        return if version == '1.1'

        error_message = "JSON RPC Version #{version} is not supported"
        raise Trustly::Exception::JSONRPCVersionError, error_message
      end

      def version
        payload['version']
      end

      def method
        payload['method']
      end

      def signature
        payload.dig('params', 'signature')
      end

      def uuid
        payload.dig('params', 'uuid')
      end

      def data_at(key)
        payload.dig('params', 'data', key)
      end

      def attribute_at(key)
        payload.dig('params', 'data', 'attributes', key)
      end

      private

      def notification_body(body)
        return Utils::DataTransformer.deep_stringify_hash(body) if body.is_a?(Hash)

        JSON.parse(body)
      rescue JSON::ParserError => e
        raise Trustly::Exception::DataError, e.message
      end
    end
  end
end
