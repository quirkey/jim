# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name    = %q{jim}
  s.version = File.read(File.expand_path("VERSION", File.dirname(__FILE__))).chomp

  s.authors            = ["Aaron Quint"]
  s.date               = Date.today
  s.description        = %q{jim is your friendly javascript library manager. He downloads, stores, bundles, vendors and compresses.}
  s.email              = %q{aaron@quirkey.com}
  s.executables        = ["jim"]
  s.homepage           = %q{http://github.com/quirkey/jim}
  s.require_paths      = ["lib"]
  s.rubygems_version   = %q{1.3.7}
  s.summary            = %q{jim is your friendly javascript library manager}

  s.default_executable = %q{jim}
  s.extra_rdoc_files   = %w[LICENSE README.md]
  s.files = %w[Gemfile
               Gemfile.lock
               HISTORY
               LICENSE
               README.md
               VERSION
               Rakefile
               bin/jim
               default
               jim.gemspec] +
    Dir.glob('{lib,test}/**/*')
  s.test_files         = Dir.glob('test/**/*.rb')


  s.add_dependency 'downlow'        , "~> 0.1.4"
  s.add_dependency 'fssm'           , "~> 0.2.0"
  s.add_dependency 'thor'           , "~> 0.14.4"
  s.add_dependency 'version_sorter' , "~> 1.1.0"
  s.add_dependency 'yajl-ruby'      , ">= 0"

  s.add_development_dependency 'fakeweb'   , ">= 1.2.8"
  s.add_development_dependency 'leftright' , ">= 0"
  s.add_development_dependency 'mocha'     , ">= 0"
  s.add_development_dependency 'rack-test' , ">= 0.5.4"
  s.add_development_dependency 'rake'      , ">= 0"
  s.add_development_dependency 'shoulda'   , ">= 0"
  s.add_development_dependency 'test-unit' , ">= 0"
end
