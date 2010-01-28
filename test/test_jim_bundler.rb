require 'helper'

class TestJimBundler < Test::Unit::TestCase

  context "Jim::Bundler" do
    setup do
      # clear the tmp dir
      FileUtils.rm_rf(tmp_path) if File.directory?(tmp_path)
      root = File.dirname(__FILE__)
      @directories = [File.join(root, 'fixtures'), File.join(root, 'tmp', 'lib')]
    end
    
    context "initialize" do
      
      should "load jimfile data if jimfile is a Pathname" do
        
      end
      
      should "load jimfile data as a string" do
        
      end
      
      should "set index" do
        
      end
      
      should "set options" do
        
      end
      
    end        
    
    context "resolve!" do
      
      should "find projects listed in the jimfile and set paths" do
        
      end
      
      should "set paths in same order as in jimfile" do
        
      end
      
      should "raise error if file can not be found" do
        
      end
    
    end
    
    context "bundle!" do
      
      should "concatenate file into a string" do
        
      end
      
      should "raise error if file cant be found" do
        
      end
      
      should "write to file if path is given" do
        
      end
      
      should "write to IO if IO is given" do
        
      end
      
    end
    
    context "compress!" do
      
      should "run through google compressor" do
        
      end
      
      should "write to file if path is given" do
        
      end
      
      should "write to IO if IO is given" do
        
      end
      
    end
  end

end
