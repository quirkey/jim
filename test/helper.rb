require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fakeweb'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'jim'

Jim.logger = Logger.new('/dev/null')

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
  
  def assert_readable(*args)
    full_path = File.join(*args)
    assert File.readable?(full_path), "Expected #{full_path} to be a readable file"
  end
  
  def assert_dir(*args)
    full_path = File.join(*args)
    assert File.directory?(full_path), "Expected #{full_path} to be a directory"
  end
  
end
