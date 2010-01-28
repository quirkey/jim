require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fakeweb'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'jim'

class Test::Unit::TestCase
  
  def fixture_path(path)
    full_path = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', path))
  end
  
  def fixture(path)
    File.read(fixture_path(path))
  end
  
  def tmp_path
    File.join(File.dirname(__FILE__), 'tmp')
  end
end
