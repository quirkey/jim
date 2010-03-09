require 'helper'

class TestJimIndex < Test::Unit::TestCase

  context "Jim::Index" do
    setup do
      # clear the tmp dir
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      root = File.dirname(__FILE__)
      @directories = [File.join(root, 'fixtures'), File.join(root, 'tmp', 'lib')]
      @index = Jim::Index.new(*@directories)
    end
    
    context "initializing" do
      
      should "set an array of directories" do
        assert_equal @directories, @index.directories
      end
    end
    
    context "list" do
      setup do
        Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path, :version => '1.5pre').install
        @list = @index.list
      end
      
      should "return list of files" do
        names = @list.collect {|l| l[0] }
        assert names.include?('jquery'), "should include jquery"
        assert names.include?('infoincomments')
      end
      
      should "only return one of each name" do
        jquery = @list.find {|l| l[0] == 'jquery' }
        assert jquery, "should include jquery"
        assert jquery[1].is_a?(Array), "should have array of versions and filenames"
        assert_equal jquery[1].length, jquery[1].uniq.length
        assert jquery[1][0].is_a?(Array)
        assert jquery[1][0][0].is_a?(String), "should have version"
        assert jquery[1][0][1].is_a?(Pathname), "should include pathname"
      end
      
    end
    
    context "find" do
      
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
        jim_path = installer.install
        assert jim_path.is_a?(Pathname)
        path = @index.find('jquery', '1.5pre')
        assert_equal jim_path.expand_path, path.expand_path
      end
      
      should "find by name with dot and version 0 in jim dirs" do
        installer = Jim::Installer.new(fixture_path('jquery.color.js'), tmp_path)
        jim_path = installer.install
        assert jim_path.is_a?(Pathname)
        path = @index.find('jquery.color', '0')
        assert_equal jim_path.expand_path, path.expand_path
      end
      
      should "find by name in jim dirs" do
        installer = Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path)
        jim_path = installer.install
        assert jim_path.is_a?(Pathname)
        path = @index.find('myproject')
        assert_equal jim_path.expand_path, path.expand_path
      end
      
      should "return false if file can not be found" do
        assert !@index.find('jquery', '1.8')
      end

    end
    
    context "find_all" do
      setup do
        Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path, :version => '1.5pre').install
        @all = @index.find_all("jquery")
      end
      
      should "return array" do
        assert @all.is_a?(Array)
      end
      
      should "find all files that match the search" do
        assert @all[0].is_a?(Pathname)
        assert @all.all? {|p| p.to_s.match /jquery/ }
      end
      
    end
        
  end
end
