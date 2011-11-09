require 'rubygems'
require 'bundler'

Bundler.require


$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'jim'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "jim"
    gem.version = Jim::VERSION
    gem.summary = %Q{jim is your friendly javascript library manager}
    gem.description = %Q{jim is your friendly javascript library manager. He downloads, stores, bundles, vendors and compresses.}
    gem.email = "aaron@quirkey.com"
    gem.homepage = "http://github.com/quirkey/jim"
    gem.authors = ["Aaron Quint"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test
