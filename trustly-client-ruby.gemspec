# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trustly/version"

Gem::Specification.new do |gem|
  gem.name    = 'client-trustly-ruby'
  gem.version = Trustly::VERSION
  gem.date    = Date.today.to_s

  gem.summary = "Trustly Client Ruby Support"
  gem.description = "Support for Ruby use of trustly API"

  gem.authors  = ['Jorge Carretie']
  gem.email    = 'jorge@carretie.com'
  gem.homepage = 'https://github.com/jcarreti/trusty-client-ruby'

  gem.add_dependency('rake')
  gem.add_development_dependency('rspec', [">= 2.0.0"])

  # ensure the gem is built out of versioned files
  gem.files = Dir['{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*']
end