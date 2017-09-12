ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/reporters'

# wider padding of test names
#   ovveride in gem minitest-reporters
#   see https://github.com/kern/minitest-reporters/blob/master/lib/minitest/relative_position.rb

module Minitest
  module RelativePosition
    def pad_test(str)
      pad("%-100s" % str[5..-1], TEST_PADDING)
    end
  end
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# monkey patch to support link and unlink helpers
module ActionDispatch::Integration::RequestHelpers

  [:get,:put,:patch,:post,:delete,:link,:unlink].each do |method_name|
    define_method method_name do |path, *args|
      case Rails.version
      when /\A4\./   
        process method_name, path, args.first.try(:fetch,:params, nil), args.first.try(:fetch,:headers, nil)
      when /\A5\.0\./
        process_with_kwargs(method_name, path, *args) 
      when /\A5\.1/
        process method_name, path, *args
      else
        raise "Rails version #{Rails.version} is not supported."        
      end
    end
  end
end

def mkhd accept: 'application/json', token: 'TOK_default', range: nil
  hdr = {}
  hdr["HTTP_ACCEPT"] = accept if accept
  hdr["Range"] = 'items=' + range if range
  hdr["HTTP_AUTHORIZATION"] =  ActionController::HttpAuthentication::Token.encode_credentials(token) if token
  hdr
end
