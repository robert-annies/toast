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

#Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
