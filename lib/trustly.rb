# frozen_string_literal: true

module Trustly
end

require 'base64'
require 'openssl'
require 'stringio'
require 'faraday'
require 'faraday_middleware'

require 'trustly/exception/base'
require 'trustly/exception/authentification_error'
require 'trustly/exception/connection_error'
require 'trustly/exception/data_error'
require 'trustly/exception/configuration_error'
require 'trustly/exception/jsonrpc_version_error'
require 'trustly/exception/signature_error'

require 'trustly/utils/data_transformer'
require 'trustly/utils/data_cleaner'

require 'trustly/data/base'
require 'trustly/data/request'
require 'trustly/data/response'
require 'trustly/data/jsonrpc_request'
require 'trustly/data/jsonrpc_response'
require 'trustly/data/jsonrpcnotification_request'
require 'trustly/data/jsonrpcnotification_response'

require 'trustly/api/base'
require 'trustly/api/signed'
require 'trustly/version'
