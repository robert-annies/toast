#!/usr/bin/env ruby
File.open("../summary.log",'a') do |summary|
  `rm -f Gemfile.lock`

  system 'gem  install bundle -ivendor/gems --no-ri --no-rdoc'
  system 'rbenv rehash'
  puts
  puts "    installing gems for #{ENV['TOAST_TEST_RAILS_VERSION']} in #{`pwd`.chomp}/vendor/gems"
  system 'bundle install --path vendor/gems'

  unless $?.success?
    summary.puts "* Ruby #{RUBY_VERSION} - Rails #{ENV['TOAST_TEST_RAILS_VERSION']}: failed to install gems"
  else

    puts "    setting up database (sqlite)"
    system 'bundle exec rake db:setup'


    actual_rails_version = `bundle show rails`.split('-').last.chomp

    puts "="*60
    puts "Running test suite with Ruby #{RUBY_VERSION} and Rails #{actual_rails_version}"
    puts "="*60

    system 'bundle exec rake test'

    unless $?.success?
      puts
      puts "FAILED: Test suite failed for rails version #{actual_rails_version}"
      puts
      summary.puts "* Ruby #{RUBY_VERSION} - Rails #{actual_rails_version}: tests failed"
    else
      summary.puts "* Ruby #{RUBY_VERSION} - Rails #{actual_rails_version}: tests succeeded"
    end
  end
end
