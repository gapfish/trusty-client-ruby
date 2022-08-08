module Trustly
  module Api
    class Base
      attr_accessor :api_host,
        :api_port,
        :api_is_https,
        :last_request,
        :trustly_key

      def initialize(**config)
        self.api_host = config[:host]
        self.api_port = config[:port]
        self.api_is_https = config[:is_https]

        self.load_trustly_key(config[:public_pem])
        validate!
      end

      def verify_signed_response(response)
        method = response.method || ''
        uuid = response.uuid || ''
        raw_signature = Base64.decode64(response.signature || '')
        serial_data = "#{method}#{uuid}#{self.serialize(response.data)}"
        trustly_key.public_key.verify(
          OpenSSL::Digest::SHA1.new, raw_signature, serial_data
        )
      end

      private

      def url_path(_request = nil)
        raise NotImplementedError
      end

      def handle_response(_request, _http_call)
        raise NotImplementedError
      end

      def insert_credentials(_request)
        raise NotImplementedError
      end

      def serialize(object)
        serialized = ""
        case object
        when Array then serialize_array(object, serialized)
        when Hash then serialize_hash(object, serialized)
        else serialized.concat(object.to_s)
        end
        serialized
      end

      def serialize_array(object, serialized)
        object.each { |value| serialized.concat(serialize(value)) }
      end

      def serialize_hash(object, serialized)
        object.sort.each do |key, value|
          serialized.concat(key.to_s).concat(serialize(value))
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
        return URI.parse("#{self.base_url}#{url_path(request)}")
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
        message = e.message
        exception = case error
                    when Faraday::ParsingError, Trustly::ClientError
                      Trustly::Exception::DataError
                    else
                      Trustly::Exception::ConnectionError
                    end
        unless (response = error.response).nil?
          message = "
            #{response.status}: #{response.body} - #{request.method}, #{body}
          "
        end
        raise exception, message
      end

      def connection(request_uri)
        Faraday.new(request_uri.origin) do |conn|
          conn.response :json
          conn.adapter :net_http
        end
      end
    end
  end
end
