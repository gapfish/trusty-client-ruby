# frozen_string_literal: true

module Trustly
  module Utils
    class DataCleaner
      class << self
        def vacuum(data)
          case data
          when Array then vacuum_array_data(data)
          when Hash then vacuum_hash_data(data)
          else data
          end
        end

        private

        def vacuum_array_data(data)
          ret = data.filter_map { |element| vacuum(element) }
          ret.empty? ? nil : ret
        end

        def vacuum_hash_data(data)
          ret = data.each_with_object({}) do |(key, element), acc|
            next if (processed_element = vacuum(element)).nil?

            acc[key] = processed_element
          end
          ret.empty? ? nil : ret
        end
      end
    end
  end
end
