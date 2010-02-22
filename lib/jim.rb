require 'downlow'
require 'logger'
require 'yajl'


module Jim
  VERSION = '0.1.2'
  
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
  
  def self.each_path_in_directories(directories, ext, ignore_directories = [], &block)
    ignore_regexps = ignore_directories.collect {|d| Regexp.new(d + '/') }
    directories.each do |dir|
      dir = Pathname.new(dir).expand_path
      Dir.glob(Pathname.new(dir) + '**' + "*#{ext}") do |filename|
        basepath = filename.to_s.gsub(dir.to_s, '')
        next if ignore_regexps.any? {|i_regexp| basepath =~ i_regexp }
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