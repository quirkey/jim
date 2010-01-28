require 'helper'

class TestJimBundler < Test::Unit::TestCase

  context "Jim::Bundler" do
    setup do
      # clear the tmp dir
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      root = File.dirname(__FILE__)
      @directories = [File.join(root, 'fixtures'), File.join(root, 'tmp', 'lib')]
      Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path).run
      @bundler = Jim::Bundler.new(fixture('jimfile'), Jim::Index.new(@directories))
    end
    
    context "initialize" do
      
      should "load jimfile data if jimfile is a Pathname" do
        @bundler = Jim::Bundler.new(Pathname.new(fixture_path('jimfile')), Jim::Index.new(@directories))
        assert @bundler
        assert_equal fixture('jimfile'), @bundler.jimfile
      end
      
      should "load jimfile data as a string" do
        assert @bundler
        assert_equal fixture('jimfile'), @bundler.jimfile
      end
      
      should "set index" do
        assert @bundler.index.is_a?(Jim::Index)
        assert_equal @directories, @bundler.index.directories
      end      
    end        
    
    context "resolve!" do
      
      should "find projects listed in the jimfile and set paths" do
        assert @bundler.paths.empty?
        @bundler.resolve!
        assert @bundler.paths
        assert_equal 2, @bundler.paths.length
        @bundler.paths.each do |path|
          assert path.is_a?(Pathname)
        end
      end
      
      should "set paths in same order as in jimfile" do
        @bundler.resolve!
        assert_equal Pathname.new(fixture_path('jquery-1.4.1.js')), @bundler.paths.first
      end
      
      should "raise error if file can not be found" do
        FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
        assert_raise(Jim::Bundler::MissingFile) {
          @bundler.resolve!
        }
      end
    
    end
    
    context "localize!" do
      
      should "copy files in jemfile to path specified" do
        
      end
      
    end
    
    context "bundle!" do
      
      should "concatenate file into a string" do
        bundle = @bundler.bundle!
        assert bundle.is_a?(String)
        assert_match(/jQuery/, bundle)
      end
      
      should "raise error if file cant be found" do
        FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
        assert_raise(Jim::Bundler::MissingFile) {
          @bundler.bundle!
        }
      end
      
      should "write to file if path is given" do
        bundle_path = File.join(tmp_path, 'app.js')
        assert @bundler.bundle!(bundle_path)
        assert bundle = File.read(bundle_path)
        assert_match(/jQuery/, bundle)
      end
      
      should "write to IO if IO is given" do
        bundle_path = File.join(tmp_path, 'app.js')
        assert @bundler.bundle!(File.open(bundle_path, 'w'))
        assert bundle = File.read(bundle_path)
        assert_match(/jQuery/, bundle)
      end
      
    end
    
    context "compress!" do
      
      should "run through google compressor" do
        Closure::Compiler.any_instance.expects(:compress).once
        bundle = @bundler.compress!
        assert bundle.is_a?(String)
        assert_match(/jQuery/, bundle)
      end
      
      should "write to file if path is given" do
        Closure::Compiler.any_instance.expects(:compress).once
        bundle_path = File.join(tmp_path, 'app.js')
        assert @bundler.compress!(bundle_path)
        assert bundle = File.read(bundle_path)
        assert_match(/jQuery/, bundle)        
      end
      
      should "write to IO if IO is given" do
        Closure::Compiler.any_instance.expects(:compress).once
        bundle_path = File.join(tmp_path, 'app.js')
        assert @bundler.compress!(File.open(bundle_path, 'w'))
        assert bundle = File.read(bundle_path)
        assert_match(/jQuery/, bundle)
      end
      
    end
  end

end
