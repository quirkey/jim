require 'helper'

class TestJimInstaller < Test::Unit::TestCase

  context "Jim::Installer" do
    setup do
      # clear the tmp dir
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
    end
    
    context "initializing" do
      setup do
        @installer = Jim::Installer.new('fetchpath', 'installpath', {:version => '1.1'})
      end
      
      should "set fetch path" do
        assert_equal 'fetchpath', @installer.fetch_path
      end
      
      should "set install path" do
        assert_equal 'installpath', @installer.install_path
      end
      
      should "set options" do
        assert_equal({:version => '1.1'}, @installer.options)
      end
      
    end
    
    context "fetch" do
      setup do
        @url = "http://jquery.com/download/jquery-1.4.1.js"
        FakeWeb.register_uri(:get, @url, :body => fixture('jquery-1.4.1.js'))
      end
      
      should "fetch remote file" do
        installer = Jim::Installer.new(@url, tmp_path)
        assert installer.fetch
      end
      
      should "put file into temporary directory" do
        installer = Jim::Installer.new(@url, tmp_path)
        installer.fetch
        assert File.directory?(File.join(tmp_path, 'tmp', 'jquery-1.4.1'))
        assert File.readable?(File.join(tmp_path, 'tmp', 'jquery-1.4.1', 'jquery-1.4.1.js'))
      end
      
      should_eventually "unpack gzips" do
        
      end
      
      should "fetch local file" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path)
        installer.fetch
        assert File.directory?(File.join(tmp_path, 'tmp', 'jquery-1.4.1'))
        assert File.readable?(File.join(tmp_path, 'tmp', 'jquery-1.4.1', 'jquery-1.4.1.js'))
      end
      
    end
    
    context "determine_name" do
      
      should "determine name from filename" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_name
        assert_equal 'jquery', installer.name
      end
      
      should_eventually "determine name from package.json"
      
      should "determine name from file comments" do
        installer = Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_name
        assert_equal 'myproject', installer.name
      end
      
      should "determine name from options" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path, :name => 'myproject')
        assert installer.fetch
        assert installer.determine_name
        assert_equal 'myproject', installer.name
      end      
    end
    
    context "determine_version" do
      
      should "determine version from filename" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_version
        assert_equal '1.4.1', installer.version
      end
      
      should_eventually "determine version from META.json"
      
      should "determine version from file comments" do
        installer = Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_version
        assert_equal '1.2.2', installer.version
      end
      
      should "determine version from options" do
        installer = Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path, :version => '1.0pre')
        assert installer.fetch
        assert installer.determine_version
        assert_equal '1.0pre', installer.version
      end
    end
    
    context "install" do
      
      should "move file into install path at name/version" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path)
        assert installer.fetch
        assert installer.install
        install_path = File.join(tmp_path, 'jquery', '1.4.1')
        assert File.directory?(install_path)
        assert File.readable?(File.join(install_path, 'jquery.js'))
        assert_equal fixture('jquery-1.4.1.js'), File.read(File.join(install_path, 'jquery.js'))
      end
      
    end
    
  end
end
