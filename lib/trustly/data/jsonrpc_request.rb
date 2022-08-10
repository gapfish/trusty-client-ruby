# frozen_string_literal: true

module Trustly
  module Data
    class JSONRPCRequest < Request
      def initialize(**options)
        super(**options.slice(:method, :payload))

        data = options[:data]
        attributes = options[:attributes]
        payload['params'] ||= {}
        payload['version'] ||= 1.1

        initialize_data_and_attributes(data, attributes)
      end

      def params
        payload['params']
      end

      def data
        params['Data']
      end

      def attributes
        params.dig('Data', 'Attributes')
      end

      def data_at(name)
        params.dig('Data', name)
      end

      def attribute_at(name)
        params.dig('Data', 'Attributes', name)
      end

      def update_data_at(name, value)
        params['Data'] ||= {}
        params['Data'][name] = value
      end

      def update_attribute_at(name, value)
        params['Data'] ||= {}
        params['Data']['Attributes'] ||= {}
        params['Data']['Attributes'][name] = value
      end

      def signature
        params['Signature']
      end

      def signature=(value)
        params['Signature'] = value
      end

      def method=(value)
        super
        payload['method'] = method
      end

      def uuid
        params['UUID']
      end

      def uuid=(value)
        params['UUID'] = value
      end

      private

      def initialize_data_and_attributes(data, attributes)
        return if data.nil? && attributes.nil?

        initialize_data(data, !attributes.nil?)
        initialize_attributes(attributes)
      end

      def initialize_data(data, with_attributes)
        if data.nil?
          payload['params']['Data'] ||= {}
        else
          raise TypeError, 'Data must be a Hash if attributes are provided' if !data.is_a?(Hash) && with_attributes

          payload['params']['Data'] = vacuum(data)
        end
      end

      def initialize_attributes(attributes)
        return if attributes.nil?

        payload['params']['Data']['Attributes'] ||= vacuum(attributes)
      end
    end
  end
end
