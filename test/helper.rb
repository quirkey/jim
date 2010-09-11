require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fakeweb'
require 'mocha'
require 'leftright'
# require 'test_benchmark'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'jim'

unless !!ENV['PRINT']
  Jim.logger = Logger.new('/dev/null')
else
  logger           = Logger.new(STDOUT)
  logger.level     = Logger::DEBUG
  logger.formatter = Proc.new {|s, t, n, msg| "\n* #{s}: #{msg}\n"}
  Jim.logger = logger
end

JIM_TMP_ROOT = File.join(File.dirname(__FILE__), 'tmp', 'jimtmproot')
Jim::Installer.tmp_root = JIM_TMP_ROOT

class Test::Unit::TestCase

  def fixture_path(path)
    full_path = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', path))
  end

  def fixture(path)
    File.read(fixture_path(path))
  end

  def tmp_path
    Pathname.new(File.join(File.dirname(__FILE__), 'tmp')).expand_path
  end

  def assert_readable(*args)
    full_path = File.join(*args)
    assert File.readable?(full_path), "Expected #{full_path} to be a readable file"
  end

  def assert_file_contents(match, *args)
    full_path = File.join(*args)
    file_contents = File.read(full_path)
    assert_match(match, file_contents, "Expected file at #{full_path} with content #{file_contents} to match #{match.inspect}")
  end

  def assert_dir(*args)
    full_path = File.join(*args)
    assert File.directory?(full_path), "Expected #{full_path} to be a directory"
  end

  def assert_not_readable(*args)
    full_path = File.join(*args)
    assert !File.readable?(full_path), "Expected #{full_path} to not be a readable file"
  end

end
