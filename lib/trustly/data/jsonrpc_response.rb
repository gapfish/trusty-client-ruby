class Trustly::Data::JSONRPCResponse < Trustly::Data::Response
  VERSION_ERROR = 'JSON RPC Version is not supported'

  def initialize(**options)
    super
    version = payload['version']
    if version != '1.1'
      raise Trustly::Exception::JSONRPCVersionError, VERSION_ERROR 
    end
  end

  def data_at(name)
    return if data.nil?
    
    data[name]
  end
end
