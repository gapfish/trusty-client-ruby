# frozen_string_literal: true

require 'rails/generators'

module Trustly
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc 'Create cert folder and trustly pem files'
      source_root ::File.expand_path('templates', __dir__)

      def copy_files
        copy_file 'test.trustly.public.pem', 'certs/trustly/test.trustly.public.pem'
        copy_file 'live.trustly.public.pem', 'certs/trustly/live.trustly.public.pem'
      end
    end
  end
end
