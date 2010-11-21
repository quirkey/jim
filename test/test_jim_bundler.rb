require 'helper'

class TestJimBundler < Test::Unit::TestCase

  context "Jim::Bundler" do
    setup do
      # clear the tmp dir
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      root = File.dirname(__FILE__)
      @directories = [File.join(root, 'tmp', 'lib'), File.join(root, 'fixtures')]
      Jim::Installer.new(fixture_path('infoincomments.js'), File.join(root, 'tmp', 'lib')).install
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

      should "parse options out of jimfile" do
        assert_equal 'test/tmp/', @bundler.bundle_dir.to_s
        assert_equal 'test/tmp/public/javascripts/vendor', @bundler.options[:vendor_dir].to_s
      end

      should "set index and include vendor dir" do
        assert @bundler.index.is_a?(Jim::Index)
        assert_equal [@bundler.options[:vendor_dir]] + @directories, @bundler.index.directories
      end

      should "parse old jimfile" do
        @bundler = Jim::Bundler.new(Pathname.new(fixture_path('old_jimfile')), Jim::Index.new(@directories))
        assert @bundler
        assert_equal fixture('old_jimfile'), @bundler.jimfile
        assert_equal 'test/tmp/public/javascripts', @bundler.bundle_dir.to_s
        assert_equal 'test/tmp/public/javascripts/vendor', @bundler.options[:vendor_dir].to_s
        assert @bundler.bundles['default']
      end
    end

    context "resolve!" do

      should "find projects listed in the jimfile and set paths" do
        assert @bundler.paths.empty?
        @bundler.resolve!
        assert @bundler.paths.is_a?(Hash)
        assert @bundler.paths['default']
        assert_equal 3, @bundler.paths['default'].length
        @bundler.paths['default'].each do |path, name, version|
          assert path.is_a?(Pathname)
          assert name.is_a?(String)
        end
      end

      should "set paths in same order as in jimfile" do
        @bundler.resolve!
        assert_equal Pathname.new(fixture_path('jquery-1.4.1.js')), @bundler.paths['default'][0][0]
      end

      should "raise error if file can not be found" do
        FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
        assert_raise(Jim::Bundler::MissingFile) {
          @bundler.resolve!
        }
      end

    end

    context "vendor!" do

      should "copy files in jimfile to path specified" do
        vendor_dir = Pathname.new(tmp_path) + 'vendor'
        @bundler.vendor!(vendor_dir)
        assert_readable vendor_dir + 'myproject-1.2.2.js'
        assert !File.readable?(vendor_dir + 'localfile.js'), "shouldnt vendor local files"
      end

    end

    context "bundle!" do

      should "concatenate file into a string" do
        @bundler.bundle_dir = nil
        bundle = @bundler.bundle!("default")
        assert bundle.is_a?(String)
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
      end

      should "raise error if file cant be found" do
        FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
        assert_raise(Jim::Bundler::MissingFile) {
          @bundler.bundle!
        }
      end

      should "write to file specified in options" do
        bundle_dir = @bundler.bundle_dir
        assert @bundler.bundle!
        assert bundle = File.read(bundle_dir + 'default.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
      end

      should "write all files if path is given" do
        bundle_dir = @bundler.bundle_dir
        assert @bundler.bundle!
        assert bundle = File.read(bundle_dir + 'default.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
        assert bundle = File.read(bundle_dir + 'base.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
      end

      should "write specific bundle if given" do
        bundle_dir = @bundler.bundle_dir
        assert @bundler.bundle!("base")
        assert bundle = File.read(bundle_dir + 'base.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
      end

      should "raise error if no bundle path or bundle name is specified" do
        @bundler.bundle_dir = nil
        assert_raise(Jim::Bundler::InvalidBundle) {
          @bundler.bundle!
        }
      end

      should "return array of paths" do
        bundle_dir = @bundler.bundle_dir
        assert paths = @bundler.bundle!
        assert paths.is_a?(Array)
        assert_contains paths, bundle_dir + 'base.js'
        assert_contains paths, bundle_dir + 'default.js'
      end

    end

    context "compress!" do
      setup do
        @bundler.stubs(:compress_js).returns("jQuery")
      end

      should "run through google compressor" do
        @bundler.bundle_dir = nil
        bundle = @bundler.compress!("default")
        assert bundle.is_a?(String)
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
      end

      should "write to dir specified in options" do
        bundle_path = @bundler.bundle_dir
        assert @bundler.compress!
        assert bundle = File.read(bundle_path + 'default.min.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
        assert bundle = File.read(bundle_path + 'base.min.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
      end

      should "write specific bundle if given" do
        bundle_path = @bundler.bundle_dir
        assert @bundler.compress!("base")
        assert bundle = File.read(bundle_path + 'base.min.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
        assert !File.readable?(bundle_path + 'default.min.js')
      end

      should "use compressed_suffix option" do
        @bundler.options[:compressed_suffix] = '-min'
        bundle_path = @bundler.bundle_dir
        assert @bundler.compress!("base")
        assert bundle = File.read(bundle_path + 'base-min.js')
        assert_match(/jQuery/, bundle, "Bundle should include jQuery")
      end
    end

    context "jimfile_to_json" do
      should "convert back to JSON string" do
        json = @bundler.jimfile_to_json
        assert json
        assert json.is_a?(String)
        assert_match(/^\{/, json)
      end
    end

  end

end
