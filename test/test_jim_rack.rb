require 'helper'
require 'rack/test'
require 'rack'
require 'jim/rack'


class TestJimRack < Test::Unit::TestCase
  include Rack::Test::Methods

  BundledUri = '/javascripts/bundled-live.js'
  CompressedUri = '/javascripts/compressed-live.js'

  def app
    jimfile = fixture_path('jimfile')
    Rack::Builder.new {
      use Jim::Rack, :bundled_uri => BundledUri,
                     :compressed_uri => CompressedUri,
                     :jimfile => jimfile,
                     :jimhome => File.join(File.dirname(__FILE__), 'tmp')
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['okay'] ] }
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
      directories = [File.join(root, 'tmp', 'lib'), File.join(root, 'fixtures')]
      @bundler = Jim::Bundler.new(fixture('jimfile'), Jim::Index.new(directories))
    end

    # TODO: how do we really test this?
    should "respond wih bundled javascript" do
      get BundledUri
      assert_match(/jQuery/, last_response.body)
    end

    # TODO: how do we really test this?
    should "respond with compressed javascript" do
      get CompressedUri
      assert last_response.ok?
    end
  end
end
