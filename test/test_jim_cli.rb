require 'helper'

class TestJimCLI < Test::Unit::TestCase

  context "Jim::CLI" do
    setup do
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
    end
    
    context "init" do
      should "write jimfile to path" do
        run_cli("init", tmp_path)
        assert_readable
      end
    end
    
    context "bundle" do
      should "write bundle jimfile to path" do
        
      end
      
      should "write to bundled_path if no path provided" do
        
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
      should "install path to install path" do 
        
      end
      
      should "install path to default install path" do
        
      end
    end
    
  end
  
  def run_cli(*args)
    Jim::CLI.new(args.collect {|a| a.to_s })
  end
  
end