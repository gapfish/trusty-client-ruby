module Trustly
end

require 'base64'
require 'openssl'
require 'faraday'
require 'faraday_middleware'

require 'trustly/exception'
require 'trustly/exception/authentification_error'
require 'trustly/exception/connection_error'
require 'trustly/exception/data_error'
require 'trustly/exception/configuration_error'
require 'trustly/exception/jsonrpc_version_error'
require 'trustly/exception/signature_error'

require 'trustly/data'
require 'trustly/data/request'
require 'trustly/data/response'
require 'trustly/data/jsonrpc_request'
require 'trustly/data/jsonrpc_response'
require 'trustly/data/jsonrpcnotification_request'
require 'trustly/data/jsonrpcnotification_response'

require 'trustly/api'
require 'trustly/api/signed'
require 'trustly/version'
