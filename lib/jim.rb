require 'downlow'
require 'logger'
require 'yajl'


module Jim
  VERSION = '0.1.1'
  
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
      @logger.formatter = Proc.new {|s, t, n, msg| "#{msg}\n"}
      @logger
    end
    @logger
  end
  
  autoload :Installer, 'jim/installer'
  autoload :Index, 'jim/index'
  autoload :Bundler, 'jim/bundler'
  autoload :VersionParser, 'jim/version_parser'
  autoload :CLI, 'jim/cli'
end