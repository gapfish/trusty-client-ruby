# frozen_string_literal: true

module Trustly
  module Api
    class Signed < Base # rubocop:disable Metrics/ClassLength
      DEFAULT_API_PATH = '/api/1'
      SIGNATURE_ERROR = 'Incoming message signature is not valid'
      UUID_MISMATCH = 'Incoming response is not related to the request. UUID mismatch.'

      attr_accessor :api_username,
                    :api_password,
                    :merchant_key

      def initialize(**config)
        full_config = default_config.merge(config)
        self.api_username = full_config.fetch(:username, nil)
        self.api_password = full_config.fetch(:password, nil)
        load_merchant_key(full_config[:private_pem])

        super(**full_config.slice(*%i[host port is_https public_pem]))
      end

      def void(**options)
        required = %w[OrderId]
        data = %w[OrderId]
        call_rpc_for_data('Void', options, data: data, required: required)
      end

      def deposit(**options) # rubocop:disable Metrics/MethodLength
        required = %w[
          Locale Country Currency SuccessURL FailURL NotificationURL Amount
          EndUserID MessageID Firstname Lastname ShopperStatement
        ]
        attributes = %w[
          Locale Country Currency SuggestedMinAmount SuggestedMaxAmount Amount
          IP SuccessURL FailURL TemplateURL URLTarget MobilePhone ShopperStatement
          Firstname Lastname NationalIdentificationNumber Email AccountID
          UnchangeableNationalIdentificationNumber ShippingAddressCountry
          ShippingAddressPostalCode ShippingAddressLine1 ShippingAddressLine2
          ShippingAddress RequestDirectDebitMandate ChargeAccountID QuickDeposit
          URLScheme ExternalReference PSPMerchant PSPMerchantURL
          MerchantCategoryCode RecipientInformation
        ]
        data = %w[NotificationURL EndUserID MessageID]
        call_rpc_for_data(
          'Deposit',
          options, data: data, attributes: attributes, required: required
        )
      end

      def refund(**options)
        required = %w[OrderId Amount Currency]
        data = %w[OrderId Amount Currency]
        attributes = %w[ExternalReference]
        call_rpc_for_data(
          'Refund', options,
          data: data, attributes: attributes, required: required
        )
      end

      def select_account(**options) # rubocop:disable Metrics/MethodLength
        required = %w[
          Locale Country SuccessURL FailURL NotificationURL EndUserID MessageID
          Firstname Lastname
        ]
        attributes = %w[
          Locale Country Firstname Lastname SuccessURL FailURL Email IP
          RequestDirectDebitMandate TemplateURL URLTarget MobilePhone
          NationalIdentificationNumber UnchangeableNationalIdentificationNumber
          ShopperStatement DateOfBirth URLScheme PSPMerchant PSPMerchantURL
          MerchantCategoryCode
        ]
        data = %w[NotificationURL EndUserID MessageID]
        call_rpc_for_data(
          'SelectAccount', options,
          data: data, attributes: attributes, required: required
        )
      end

      def account_payout(**options) # rubocop:disable Metrics/MethodLength
        required = %w[
          NotificationURL AccountID EndUserID MessageID Amount Currency
          ShopperStatement
        ]
        data = %w[
          NotificationURL AccountID EndUserID MessageID Amount Currency
        ]
        attributes = %w[
          ShopperStatement PSPMerchant PSPMerchantURL
          ExternalReference MerchantCategoryCode SenderInformation
        ]
        call_rpc_for_data(
          'AccountPayout', options,
          data: data, attributes: attributes, required: required
        )
      end

      def register_account(**options) # rubocop:disable Metrics/MethodLength
        required = %w[
          EndUserID ClearingHouse BankNumber AccountNumber Firstname Lastname
        ]
        data = %w[
          EndUserID ClearingHouse BankNumber AccountNumber Firstname Lastname
        ]
        attributes = %w[
          DateOfBirth MobilePhone NationalIdentificationNumber AddressCountry
          AddressPostalCode AddressCity AddressLine1 AddressLine2 Address Email
        ]
        call_rpc_for_data(
          'RegisterAccount', options,
          data: data, attributes: attributes, required: required
        )
      end

      def get_withdrawals(**options)
        data = %w[OrderId]
        required = %w[OrderId]
        call_rpc_for_data(
          'GetWithdrawals', options,
          data: data, required: required
        )
      end

      def notification_response(request, success: true)
        response = Trustly::Data::JSONRPCNotificationResponse.new(
          request: request, success: success
        )
        response.signature = sign_merchant_request(response)
        response
      end

      private

      def load_merchant_key(pkey)
        self.merchant_key = OpenSSL::PKey::RSA.new(pkey) if pkey
      rescue OpenSSL::PKey::RSAError
        self.merchant_key = nil
      end

      def configuration_errors
        errors = super
        errors.push 'Username not specified' if api_username.nil?
        errors.push 'Password not specified' if api_password.nil?
        errors.push 'Merchant private key not specified' if merchant_key.nil?
        errors
      end

      def handle_response(request, response)
        rpc_response = Trustly::Data::JSONRPCResponse.new(http_response: response)
        check_response(rpc_response, request)
        rpc_response
      end

      def check_response(response, request)
        raise Trustly::Exception::DataError, UUID_MISMATCH if response.uuid != request.uuid
        raise Trustly::Exception::SignatureError, SIGNATURE_ERROR unless verify_signed_response(response)
      end

      def insert_credentials!(request)
        request.update_data_at('Username', api_username)
        request.update_data_at('Password', api_password)
        request.signature = sign_merchant_request(request)
      end

      def sign_merchant_request(request)
        method = request.method || ''
        uuid = request.uuid || ''
        data = request.data || {}

        serial_data = "#{method}#{uuid}#{serialize(data)}"
        sha1hash = OpenSSL::Digest.new('SHA1')
        signature = merchant_key.sign(sha1hash, serial_data)
        Base64.encode64(signature).chop
      end

      def url_path(_request = nil)
        DEFAULT_API_PATH
      end

      def call_rpc(request)
        request.uuid = SecureRandom.uuid if request.uuid.nil?
        super(request)
      end

      def call_rpc_for_data(method, options, data:, required:, attributes: [])
        missing_options = required.find_all { |req| options[req].nil? }
        unless missing_options.empty?
          msg = "Required data is missing: #{missing_options.join('; ')}"
          raise Trustly::Exception::DataError, msg
        end
        request = Trustly::Data::JSONRPCRequest.new(
          method: method, data: options.slice(*data),
          attributes: attributes.empty? ? nil : options.slice(*attributes)
        )
        call_rpc(request)
      end

      def default_config
        {
          host: 'test.trustly.com',
          port: 443,
          is_https: true,
          private_pem: ENV.fetch('MERCHANT_PRIVATE_KEY', nil),
          public_pem: ENV.fetch('TRUSTLY_PUBLIC_KEY', nil)
        }
      end
    end
  end
end
