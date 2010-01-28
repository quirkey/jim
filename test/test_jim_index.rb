require 'helper'

class TestJimIndex < Test::Unit::TestCase

  context "Jim::Index" do
    setup do
      # clear the tmp dir
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      root = File.dirname(__FILE__)
      @directories = [File.join(root, 'fixtures'), File.join(root, 'tmp', 'lib')]
    end
    
    context "initializing" do
      setup do
        @index = Jim::Index.new(*@directories)
      end
      
      should "set an array of directories" do
        assert_equal @directories, @index.directories
      end
    end
    
    context "find" do
      setup do
        @index = Jim::Index.new(*@directories)
      end
      
      should "find by name and version in local files" do
        path = @index.find('jquery', '1.4.1')
        assert path
        assert path.is_a?(Pathname)
        assert_equal Pathname.new(fixture_path('jquery-1.4.1.js')), path
      end
      
      should "find by name alone in local files" do
        path = @index.find('jquery')
        assert path
        assert path.is_a?(Pathname)
        assert_equal Pathname.new(fixture_path('jquery-1.4.1.js')), path
      end
      
      should "find by path and version in local files" do
        path = @index.find('fixtures/jquery')
        assert path
        assert path.is_a?(Pathname)
        assert_equal Pathname.new(fixture_path('jquery-1.4.1.js')), path
      end
      
      should "find by name and version in jim dirs" do
        installer = Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path, :version => '1.5pre')
        jim_path = installer.run
        assert jim_path.is_a?(Pathname)
        path = @index.find('jquery', '1.5pre')
        assert_equal jim_path, path 
      end
      
      should "find by name in jim dirs" do
        installer = Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path)
        jim_path = installer.run
        assert jim_path.is_a?(Pathname)
        path = @index.find('myproject')
        assert_equal jim_path, path 
      end
      
      should "return false if file can not be found" do
        assert !@index.find('jquery', '1.8')
      end

    end
        
  end
end
