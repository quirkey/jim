require 'downlow'

begin
  require 'closure-compiler'
rescue LoadError
  warn "You must have the closure complier installed in order to use compress!\ngem install closure-compiler"
end

module Jim
  VERSION = '0.0.1'
  
  class Error < RuntimeError; end
  
  autoload :Installer, File.join(File.dirname(__FILE__), 'jim', 'installer.rb')
  autoload :Index, File.join(File.dirname(__FILE__), 'jim', 'index.rb')
  autoload :Bundler, File.join(File.dirname(__FILE__), 'jim', 'bundler.rb')
  autoload :CLI, File.join(File.dirname(__FILE__), 'jim', 'cli.rb')
end