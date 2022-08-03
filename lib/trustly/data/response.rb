class Trustly::Data::Response < Trustly::Data
  attr_accessor :response_status,
    :response_reason,
    :response_body,
    :response_result

  #called from Net::HTTP.get_response("trustly.com","/api_path") -> returns Net::HTTPResponse
  def initialize(**options)
    super
    http_response = options[:http_response]
    process_http_response(http_response)
  end

  def error?
    !payload['error'].nil?
  end

  def error_code
    return nil unless error?

    response_result.dig('data', 'code')
  end

  def error_message
    return nil unless error?

    response_result.dig('data', 'message')
  end

  def success?
    !payload['result'].nil?
  end

  def data
    response_result['data']
  end

  def uuid
    response_result['uuid']
  end

  def method
    response_result['method']
  end

  def signature
    response_result['signature']
  end

  private

  def process_http_response(http_response)
    self.response_status = http_response.status
    self.response_reason = http_response.reason_phrase
    init_response_result(http_response.body)
  end

  def init_response_result(body)
    self.payload = body
    self.response_result = payload['result'] || payload.dig('error', 'error')
    return unless response_result.nil?

    message = "No result or error in response #{payload}"
    raise Trustly::Exception::DataError, message
end
