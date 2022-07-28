class Trustly::Data::JSONRPCRequest < Trustly::Data::Request
  def initialize(**options)
    super(**options.slice(:method, :payload))

    data = options[:data]
    attributes = options[:attributes]
    payload['params'] ||= {}
    payload['version'] ||= '1.1'

    initialize_data_and_attributes(data, attributes)
  end

  def params(name)
    payload['params']
  end

  def data
    params['Data']
  end

  def data_at(name)
    params.dig('Data', name)
  end

  def attribute_at(name)
    params.dig('Data', 'Attributes', name)
  end

  def update_data_at(name, value)
    params['Data'] ||= {}
    params['Data'][name] = value
  end

  def update_attribute_at(name, value)
    params['Data'] ||= {}
    params['Data']['Attributes'] ||= {}
    params['Data']['Attributes'][name] = value
  end

  def signature
    params['Signature']
  end

  def signature=(value)
    params['Signature'] = value
  end

  def method=(value)
    super
    payload['method'] = method
  end

  def uuid
    params['UUID']
  end

  def uuid=(value)
    params['UUID'] = value
  end

  private

  def initialize_data_and_attributes(data, attributes)
    return if data.nil? && attributes.nil?
    
    if data.nil?
      payload['params']['Data'] ||= {}
    else
      if !data.is_a?(Hash) && !attributes.nil?
        raise TypeError, 'Data must be a Hash if attributes are provided'
      end
      payload['params']['Data'] = vacuum(data)
    end
    return if attributes.nil?
 
    payload['params']['Data']['Attributes'] ||= vacuum(attributes)
  end
end
