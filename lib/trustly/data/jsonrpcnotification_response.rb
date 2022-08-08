module Trustly
  module Data
    class JSONRPCNotificationResponse < Base
      def initialize(**options)
        super
        request = options[:request]
        success = options[:success]

        self.version = '1.1'
        self.uuid = request.uuid if request.uuid
        self.method = request.method if request.method
        self.update_data_at('status', success ? 'OK' : 'FAILED')
      end

      def signature=(value)
        update_result_at('signature', value)
      end

      def method=(value)
        update_result_at('method', value)
      end

      def uuid=(value)
        update_result_at('uuid', value)
      end

      def version=(value)
        payload['version'] = value
      end

      def update_result_at(name, value)
        payload['result'] ||= {}
        payload['result'][name] = value
      end

      def update_data_at(name, value)
        payload['result'] ||= {}
        payload['result']['data'] ||= {}
        payload['result']['data'][name] = value
      end

      def data
        payload.dig('result', 'data')
      end

      def result
        payload['result']
      end

      def method
        result['method']
      end

      def uuid
        result['uuid']
      end

      def signature
        result['signature']
      end
    end
  end
end
