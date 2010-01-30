require 'helper'

class TestJimCLI < Test::Unit::TestCase

  context "Jim::CLI" do
    setup do
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      Jim::Installer.new(fixture_path('infoincomments.js'), tmp_path).install
      Jim::Installer.new(fixture_path('jquery-1.4.1.js'), tmp_path).install
    end
    
    context "init" do
      should "write jimfile to path" do
        run_cli("init", tmp_path)
        assert_readable tmp_path, "jimfile"
      end
    end
    
    context "bundle" do
      should "write bundle jimfile to path" do
        run_cli("bundle", tmp_path + '/bundle.js')
        assert_readable tmp_path + '/bundle.js'
      end
      
      should "write to bundled_path if no path provided" do
        
        run_cli("bundle", "-j", fixture_path('jimfile'), "--jimhome", tmp_path)
        assert_readable File.join(tmp_path, 'public', 'javasripts', 'bundled.js')
      end
    end
    
    context "compress" do
      should "compress jimfile to path" do
        
      end
      
      should "compress to compressed_path if no path provided" do
        
      end
    end
    
    context "vendor" do
      should "vendor jimfile to dir" do
        
      end
      
      should "vendor jimfile to vendor dir" do
        
      end
    end
    
    context "resolve" do
      should "output resolved paths" do
        
      end
    end
    
    context "install" do
      should "install url to jim home" do 
        run_cli("install", fixture_path('jquery-1.4.1.js'), "--jimhome", tmp_path)
        install_path = File.join(tmp_path, 'lib', 'jquery', '1.4.1')
        assert_dir install_path
        assert_readable install_path, 'jquery.js'
        assert_equal fixture('jquery-1.4.1.js'), File.read(File.join(install_path, 'jquery.js'))
      end      
    end
    
  end
  
  def run_cli(*args)
    Jim::CLI.new(args.collect {|a| a.to_s })
  end
  
end