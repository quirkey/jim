require 'helper'

class TestJimCLI < Test::Unit::TestCase

  context "Jim::CLI" do
    setup do
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      other_tmp_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..' 'tmp'))
      FileUtils.rm_rf(other_tmp_path) if File.directory?(other_tmp_path)
      Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path).install
      Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path).install
    end

    context "init" do
      should "write Jimfile to path" do
        run_cli("init", tmp_path)
        assert_readable tmp_path, "Jimfile"
      end
    end

    context "pack" do
      should "run vendor, bundle, compress" do
        Jim::Bundler.any_instance.expects(:compress_js).twice.returns("compressed.js")
        run_cli("pack", "-j", fixture_path('Jimfile'), "--jimhome", tmp_path)
        assert_readable tmp_path, 'public', 'javascripts', 'vendor', 'jquery-1.4.1.js'
        assert_readable tmp_path, 'public', 'javascripts', 'vendor', 'myproject-1.2.2.js'
        assert_readable tmp_path, 'base.js'
        assert_readable tmp_path, 'base.min.js'
      end
    end

    context "bundle" do
      should "write all bundles to bundle_dir" do
        run_cli("bundle", "-j", fixture_path('Jimfile'), "--jimhome", tmp_path)
        assert_readable tmp_path + 'default.js'
        assert_readable tmp_path + 'base.js'
      end

      should "write specific bundle to bundle dir" do
        run_cli("bundle", "base", "-j", fixture_path('Jimfile'), "--jimhome", tmp_path)
        assert_readable tmp_path + 'base.js'
      end

      should "write bundle to provided bundle dir" do
        specific_dir = tmp_path + 'specific/'
        run_cli("bundle", '--bundle_dir', specific_dir.to_s, "-j", fixture_path('Jimfile'), "--jimhome", tmp_path)
        assert_readable specific_dir + 'default.js'
        assert_readable specific_dir + 'base.js'
      end
    end

    context "compress" do
      setup do
        Jim::Bundler.any_instance.stubs(:compress_js).returns("compressed.js")
      end

      should "compress all bundles to bundle dir" do
        run_cli("compress", "-j", fixture_path('Jimfile'), "--jimhome", tmp_path)
        assert_readable tmp_path + 'base.min.js'
        assert_readable tmp_path + 'default.min.js'
      end

      should "compress specific bundle specified" do
        run_cli("compress", "base", "-j", fixture_path('Jimfile'), "--jimhome", tmp_path)
        assert_readable tmp_path + 'base.min.js'
      end
    end

    context "vendor" do
      should "vendor Jimfile to vendor dir" do
        run_cli("vendor", "-j", fixture_path('Jimfile'), "--jimhome", tmp_path)
        assert_readable tmp_path, 'public', 'javascripts', 'vendor', 'jquery-1.4.1.js'
        assert_readable tmp_path, 'public', 'javascripts', 'vendor', 'myproject-1.2.2.js'
      end
    end

    context "install" do
      should "install url to jim home" do
        run_cli("install", fixture_path('jquery-1.4.1.js'), "--jimhome", tmp_path)
        install_path = File.join(tmp_path, 'lib', 'jquery-1.4.1')
        assert_dir install_path
        assert_readable install_path, 'jquery.js'
        assert_equal fixture('jquery-1.4.1.js'), File.read(File.join(install_path, 'jquery.js'))
      end
    end

    context "watch" do
      should_eventually "watch changed js files then run bundle" do
        #not sure how this should be tested... ideas?
      end
    end

  end

  def run_cli(*args)
    @stdout = capture(:stdout) do
      Jim::CLI.start(args.collect(&:to_s))
    end
  end

end
