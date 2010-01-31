require 'downlow'
require 'logger'

begin
  require 'closure-compiler'
rescue LoadError
  warn "You must have the closure complier installed in order to use compress!\ngem install closure-compiler"
end

module Jim
  VERSION = '0.1.0'
  
  class Error < RuntimeError; end
  class FileExists < Error; end
  
  def self.logger=(logger)
    @logger = logger
  end
  
  def self.logger
    @logger ||= LOGGER if defined?(LOGGER)
    if !@logger
      @logger           = Logger.new(STDOUT)
      @logger.level     = Logger::INFO
      @logger.formatter = Proc.new {|s, t, n, msg| "[#{t}] #{msg}\n"}
      @logger
    end
    @logger
  end
  
  autoload :Installer, 'jim/installer'
  autoload :Index, 'jim/index'
  autoload :Bundler, 'jim/bundler'
  autoload :CLI, 'jim/cli'
end