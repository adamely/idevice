require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => e
  STDERR.puts e.message
  STDERR.puts "Run `gem install bundler` to install Bundler."
  exit e.status_code
rescue Bundler::BundlerError => e
  STDERR.puts e.message
  STDERR.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
desc "run rspec unit tests"
RSpec::Core::RakeTask.new
task :default => :spec

namespace :spec do
  desc "run spec and integration tests together"
  RSpec::Core::RakeTask.new(:all) do |t|
    t.pattern = "spec/**/*_{devicespec,spec}.rb"
  end

  desc "run rspec integration tests (requires idevice connectivity)"
  RSpec::Core::RakeTask.new(:device) do |t|
    t.pattern = "spec/**/*_devicespec.rb"
  end
end

desc "pry console"
task :console do
  sh "pry -I lib -r ./lib/idev.rb"
end
