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
        assert_equal Pathname.new('fetchpath'), @installer.fetch_path
      end
      
      should "set install path" do
        assert_equal Pathname.new('installpath'), @installer.install_path
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
            
      should "fetch local file" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path)
        fetched_path = installer.fetch
        assert_dir fetched_path.dirname
        assert_equal 'jquery-1.4.1.js', fetched_path.basename.to_s
      end
      
    end
    
    context "determine_name_and_version" do
      
      should "determine from filename" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_name_and_version
        assert_equal '1.4.1', installer.version
        assert_equal 'jquery', installer.name
      end
      
      should "determine from package.json" do
        installer = Jim::Installer.new(fixture_path('mustache.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_name_and_version
        assert_equal "0.2.2", installer.version
        assert_equal "mustache", installer.name
      end
      
      should "determine from file comments" do
        installer = Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_name_and_version
        assert_equal 'myproject', installer.name
        assert_equal '1.2.2', installer.version
      end
      
      should "determine from options" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path, :name => 'myproject', :version => '1.1.1')
        assert installer.fetch
        assert installer.determine_name_and_version
        assert_equal 'myproject', installer.name
        assert_equal '1.1.1', installer.version
      end      
      
      should "have default version if version can not be determined" do
        installer = Jim::Installer.new(fixture_path('noversion.js'), tmp_path)
        assert installer.fetch
        assert installer.determine_name_and_version
        assert_equal 'noversion', installer.name
        assert_equal '0', installer.version
      end
      
    end
    
    context "install" do
      
      context "with a single file" do
        should "move file into install path at name/version" do
          installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path)
          assert installer.install
          install_path = File.join(tmp_path, 'lib', 'jquery-1.4.1')
          assert_dir install_path
          assert_readable install_path, 'jquery.js'
          assert_equal fixture('jquery-1.4.1.js'), File.read(File.join(install_path, 'jquery.js'))
        end
      end
      
      should "install zips" do
        @url = "http://jquery.com/download/jquery.metadata-2.0.zip"
        FakeWeb.register_uri(:get, @url, :body => fixture('jquery.metadata-2.0.zip'))
        installer = Jim::Installer.new(@url, tmp_path)
        path = installer.install
        # puts Dir.glob(path + '**/**').inspect 
        assert_dir path
        assert_dir path + 'jquery.metadata-2.0.zip'
        assert_readable path + 'jquery.metadata-2.0.zip' + 'jquery.metadata.2.0' +'jquery.metadata.js'
      end
      
      context "with a package" do
        setup do
          @installer = Jim::Installer.new(fixture_path('sammy-0.5.0'), tmp_path)
          @paths = @installer.install
        end
        
        should "return an array of paths" do
          assert @paths.is_a?(Array)
          assert @paths.all? {|p| p.is_a?(Pathname) }
        end
        
        should "install each js file found separately" do
          assert_dir tmp_path, 'lib', 'sammy-0.5.0'
          assert_readable tmp_path, 'lib', 'sammy-0.5.0', 'sammy.js'
          assert_readable tmp_path, 'lib', 'sammy.template-0.5.0', 'sammy.template.js'
          assert_readable tmp_path, 'lib', 'sammy.haml-0.5.0', 'sammy.haml.js'
        end
        
        should "not install files found in ignored directories" do
          assert_not_readable tmp_path, 'lib', 'qunit-spec-0.5.0', 'qunit-spec.js'
          assert_not_readable tmp_path, 'lib', 'qunit-spec-0', 'qunit-spec.js'
          assert_not_readable tmp_path, 'lib', 'test_sammy_application-0.5.0', 'test_sammy_application.js'
          assert_not_readable tmp_path, 'lib', 'test_sammy_application-0', 'test_sammy_application.js'
        end
        
      end
      
    end
    
  end
end
