require 'open-uri'
require 'fileutils'

module Jim
  VERSION = '0.0.1'

  autoload :Installer, File.join(File.dirname(__FILE__), 'jim', 'installer.rb')
end
  