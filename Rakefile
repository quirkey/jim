require 'rubygems'
require 'rake'

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

    gem.add_dependency "downlow", "~>0.1.4"
    gem.add_dependency "thor", "~>0.14.4"
    gem.add_dependency "yajl-ruby"
    gem.add_dependency "version_sorter", "~>1.1.0"
    gem.add_dependency "fssm", "~>0.2.0"
    
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_development_dependency "fakeweb", ">= 1.2.8"
    gem.add_development_dependency "mocha"
    gem.add_development_dependency "leftright"
    gem.add_development_dependency "rack-test", ">= 0.5.4"
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

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "jim #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
