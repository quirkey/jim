require 'open-uri'
require 'fileutils'

require File.join(File.dirname(__FILE__), 'jim', 'extensions', 'pathname.rb')

module Jim
  VERSION = '0.0.1'

  autoload :Installer, File.join(File.dirname(__FILE__), 'jim', 'installer.rb')
end