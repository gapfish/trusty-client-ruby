# frozen_string_literal: true

module Trustly
  module Api
    class Base # rubocop:disable Metrics/ClassLength
      attr_accessor :api_host,
                    :api_port,
                    :api_is_https,
                    :last_request,
                    :trustly_key

      def initialize(**config)
        self.api_host = config[:host]
        self.api_port = config[:port]
        self.api_is_https = config[:is_https]

        load_trustly_key(config[:public_pem])
        validate!
      end

      def verify_signed_response(response)
        method = response.method || ''
        uuid = response.uuid || ''
        raw_signature = Base64.decode64(response.signature || '')
        serial_data = "#{method}#{uuid}#{serialize(response.data)}"
        trustly_key.public_key.verify(
          OpenSSL::Digest.new('SHA1'), raw_signature, serial_data
        )
      end

      private

      def url_path(_request = nil)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      def handle_response(_request, _http_call)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      def insert_credentials(_request)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      def serialize(object)
        serialized = StringIO.new
        case object
        when Array then serialize_array(object, serialized)
        when Hash then serialize_hash(object, serialized)
        else serialized << object.to_s
        end
        serialized.string
      end

      def serialize_array(object, serialized)
        object.each { |value| serialized << serialize(value) }
      end

      def serialize_hash(object, serialized)
        object.sort.each do |key, value|
          serialized << key.to_s << serialize(value)
        end
      end

      def load_trustly_key(pkey)
        self.trustly_key = OpenSSL::PKey::RSA.new(pkey) unless pkey.nil?
      rescue OpenSSL::PKey::RSAError
        self.trustly_key = nil
      end

      def validate!
        return if configuration_errors.empty?

        errors_string = configuration_errors.join('; ')
        raise Trustly::Exception::ConfigurationError, errors_string
      end

      def configuration_errors
        errors = []
        errors.push 'Api host not specified' if api_host.nil?
        errors.push 'Trustly public key not specified' if trustly_key.nil?
        errors
      end

      def base_url
        schema = api_is_https ? 'https' : 'http'
        add_port = (api_is_https && api_port != 443) || api_port != 80
        port = add_port && !api_port.nil? ? ":#{api_port}" : ''
        "#{schema}://#{api_host}#{port}"
      end

      def url(request)
        URI.parse("#{base_url}#{url_path(request)}")
      end

      def call_rpc(request)
        insert_credentials!(request)
        self.last_request = request
        request_uri = url(request)
        body = request.to_json
        response = connection(request_uri).post(
          request_uri.path, body, { 'Content-Type' => 'application/json' }
        )
        handle_response(request, response)
      rescue Faraday::Error => e
        handle_error(e, request, body)
      end

      def handle_error(error, request, body)
        message = error.message
        exception = exception_for_error(error)
        unless error.response.nil?
          status = error.response_status
          error_body = error.response_body
          message += <<-MSG.gsub(/\s+/, ' ').rstrip
            -> #{status}: #{error_body} - #{request.method}, #{body}
          MSG
        end
        raise exception, message
      end

      def exception_for_error(error)
        case error
        when Faraday::ParsingError, Faraday::ClientError
          Trustly::Exception::DataError
        else
          Trustly::Exception::ConnectionError
        end
      end

      def connection(request_uri)
        Faraday.new(request_uri.origin) do |conn|
          # :nocov:
          conn.response :json
          conn.adapter :net_http
          # :nocov:
        end
      end
    end
  end
end
