# frozen_string_literal: true

require 'simplecov'
require 'webmock/rspec'
require 'debug'

WebMock.disable_net_connect!(allow_localhost: false)

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter]
SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 100
end

ENV['MERCHANT_PRIVATE_KEY'] ||= begin
  path = File.expand_path('data/merchant_private_key.pem', __dir__)
  File.read(path) if File.file?(path)
end

ENV['MERCHANT_PUBLIC_KEY'] ||= begin
  path = File.expand_path('data/merchant_public_key.pem', __dir__)
  File.read(path) if File.file?(path)
end

ENV['TRUSTLY_PRIVATE_KEY'] ||= begin
  path = File.expand_path('data/trustly_private_key.pem', __dir__)
  File.read(path) if File.file?(path)
end

ENV['TRUSTLY_PUBLIC_KEY'] ||= begin
  path = File.expand_path('data/trustly_public_key.pem', __dir__)
  File.read(path) if File.file?(path)
end

require 'trustly'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  # config.disable_monkey_patching!
  # config.default_formatter = 'doc' if config.files_to_run.one?
  # config.profile_examples = 10
  config.order = :random
  config.color = true
  config.tty = true
  Kernel.srand config.seed
end
