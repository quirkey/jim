require 'helper'
require 'rack/test'
require 'jim/rack'

class TestJimRack < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @bundle_uri = '/javascripts/'
  end

  def app
    jimfile = fixture_path('jimfile')
    Rack::Builder.new {
      use Jim::Rack, :bundle_uri => @bundle_uri,
                     :jimfile => jimfile,
                     :jimhome => File.join(File.dirname(__FILE__), 'tmp')
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'okay' ] }
    }
  end

  context "Jim::Rack" do
    setup do
      # clear the tmp dir
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      root = File.dirname(__FILE__)
      Jim::Installer.new(fixture_path('jquery-1.4.1.js'), File.join(root, 'tmp', 'lib')).install
      Jim::Installer.new(fixture_path('infoincomments.js'), File.join(root, 'tmp', 'lib')).install
      Jim::Installer.new(fixture_path('localfile.js'), File.join(root, 'tmp', 'lib')).install
    end

    should "get individual bundle" do
      Jim::Bundler.any_instance.expects(:bundle!).with('default').once.returns('jQuery')
      get "#{@bundle_uri}default.js"
      assert last_response
      assert_equal 'jQuery', last_response.body
      assert_equal 'text/javascript', last_response.headers['Content-Type']
    end

    should "get individual compressed bundle" do
      Jim::Bundler.any_instance.expects(:compress!).with('default').once.returns('jQuery')
      get "#{@bundle_uri}default.min.js"
      assert last_response
      assert_equal 'jQuery', last_response.body
      assert_equal 'text/javascript', last_response.headers['Content-Type']
    end

  end
end
