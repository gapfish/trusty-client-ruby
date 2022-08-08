module Trustly
  module Data
    class Base
      attr_accessor :payload

      def initialize(**_options)
        self.payload = {}
      end

      def to_json
        payload.to_json
      end

      private

      # Vacuum out all keys being set to nil in the data to be communicated
      def vacuum(data)
        case data
        when Array then vacuum_array_data(data)
        when Hash then vacuum_hash_data(data)
        else data
        end
      end

      def vacuum_array_data(data)
        ret = data.each_with_object([]) do |element, acc|
          processed_element = vacuum(element) unless element.nil?
          next if processed_element.nil?
          acc.push(processed_element)
        end
        ret.length == 0 ? nil : ret
      end

      def vacuum_hash_data(data)
        ret = data.each_with_object({}) do |(key, element), acc|
          processed_element = vacuum(element) unless element.nil?
          next if processed_element.nil?
          acc[key] = processed_element
        end
        ret.length == 0 ? nil : ret
      end

      def stringify_hash(hash)
        hash.each_with_object({}) do |(k, v), acc|
          acc[k.to_s] = v.is_a?(Hash) ? stringify_hash(v) : v
        end
      end
    end
  end
end
