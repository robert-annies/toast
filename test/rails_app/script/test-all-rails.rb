#!/usr/bin/env ruby

RAILS_VERSIONS=%w(3.0.9 3.1.0 3.2.0) 

# Note: edge Rails requires Ruby 1.9.3+ 

for rails_version in RAILS_VERSIONS
  
  ENV["TOAST_TEST_RAILS_VERSION"] = rails_version
  puts `bundle install`

  puts "="*60
  puts "Running test suite with "
  print `bundle show rails`
  puts "="*60

  unless $?.success?
    puts
    puts "FAILED: Installing rails version #{rails_version} failed"
    puts
    next
  end
    
  puts `bundle exec rake test` 

  unless $?.success?
    puts
    puts "FAILED: Test suite failed for rails version #{rails_version}"
    puts
  end

end
