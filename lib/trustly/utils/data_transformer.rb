# frozen_string_literal: true

module Trustly
  module Utils
    class DataTransformer
      def self.deep_stringify_hash(object)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), result|
            result[key.to_s] = deep_stringify_hash(value)
          end
        when Array
          object.map { |element| deep_stringify_hash(element) }
        else
          object
        end
      end
    end
  end
end
