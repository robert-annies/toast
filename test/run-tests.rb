#!/usr/bin/env ruby
require 'fileutils'
test_apps_dir = File.dirname File.expand_path(__FILE__)

FileUtils.cd test_apps_dir
FileUtils.rm_f 'summary.log'
FileUtils.touch 'summary.log'

rails_ruby_matrix = {
  '~> 3.1.0' => ['1.8.7','1.9.3','2.0.0'],
  '~> 3.2.0' => ['1.8.7','1.9.3','2.0.0'],
  '~> 4.0.0' => [        '1.9.3','2.0.0'],
  '~> 4.1.0' => [        '1.9.3','2.0.0'],
  '~> 4.2.0' => [        '1.9.3','2.0.0']#,
#  '~> 5.0.0' => ['2.2.1']
}

rails_ruby_matrix.keys.sort.each do |rails_version|
  puts "Testing for Ruby on Rails #{rails_version}"

  # change to rails app dir
  FileUtils.cd "#{test_apps_dir}/rails3_app"  if rails_version =~ /\b3\.\d+\./
  FileUtils.cd "#{test_apps_dir}/rails4_app"  if rails_version =~ /\b4\.\d+\./
  FileUtils.cd "#{test_apps_dir}/rails5_app"  if rails_version =~ /\b5\.\d+\./

  rails_ruby_matrix[rails_version].each do |ruby_version|
    print "  with Ruby #{ruby_version} "

    # check if ruby is available
    if RUBY_VERSION == ruby_version
      # use current ruby
      ENV['RBENV_VERSION'] = 'system'

    elsif `which rbenv` != ''
      # check with rbenv
      rbenv_system = `rbenv local system; ruby -v`.match(/ruby (\d\.\d\.\d)/)[1]
      rbenv_ruby   = `rbenv versions`.split.grep(/#{ruby_version}/).first

      # switch ruby with rbenv
      if ruby_version == rbenv_system
        ENV['RBENV_VERSION'] = 'system'
      elsif rbenv_ruby
        ENV['RBENV_VERSION'] = rbenv_ruby
      else
        puts 'not found, skipping (use rbenv to provide other rubies)'
        next
      end
    else
      puts 'not found, skipping  (use rbenv to provide other rubies)'
      next
    end

    # run tests
    ENV["TOAST_TEST_RAILS_VERSION"] = rails_version
    system("#{test_apps_dir}/common/install-and-test.rb")

    puts 'done'
  end
end

puts
puts '*'*60
puts '* SUMMARY'
puts File.read "#{test_apps_dir}/summary.log"
puts '*'*60
