# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trustly/version"

Gem::Specification.new do |gem|
  gem.name    = 'trustly-client-ruby'
  gem.version = Trustly::VERSION
  gem.date    = Time.now.strftime('%Y-%m-%d')
  gem.required_ruby_version = '>= 2.7'
  gem.platform = Gem::Platform::RUBY

  gem.summary = 'Trustly Client Ruby Support'
  gem.description = 'Support for Ruby use of Trustly API'

  gem.authors  = ['Jorge Carretie']
  gem.email    = 'jorge@carretie.com'
  gem.homepage = 'https://github.com/jcarreti/trusty-client-ruby'
  gem.license  = 'MIT'

  gem.add_runtime_dependency 'rake'
  gem.add_runtime_dependency 'faraday'
  gem.add_runtime_dependency 'faraday_middleware'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'debug'
  gem.add_development_dependency 'rubocop'

  # ensure the gem is built out of versioned files
  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.require_paths = ['lib']
end