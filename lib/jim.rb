require 'downlow'
require 'logger'
require 'yajl'
require 'version_sorter'
require 'digest/md5'

module Jim
  VERSION = '0.2.1'
  
  class Error < RuntimeError; end
  class InstallError < Error; end
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
  
  def self.each_path_in_directories(directories, ext, ignore_directories = [], &block)
    ignore_regexp = ignore_directories.empty? ? false : /(\/|^)(#{ignore_directories.join('|')})\//
    directories.each do |dir|
      dir = Pathname.new(dir).expand_path
      Dir.glob(Pathname.new(dir) + '**' + "*#{ext}") do |filename|
        next if File.directory?(filename)
        if ignore_regexp
          basepath = filename.to_s.gsub(dir.to_s, '/')
          next if basepath =~ ignore_regexp
        end
        yield Pathname.new(filename)
      end
    end
  end
  
  autoload :Installer, 'jim/installer'
  autoload :Index, 'jim/index'
  autoload :Bundler, 'jim/bundler'
  autoload :VersionParser, 'jim/version_parser'
  autoload :CLI, 'jim/cli'
end