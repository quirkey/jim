module Jim
  class Installer
    attr_reader :fetch_path, :install_path, :options
    
    def initialize(fetch_path, install_path, options = {})
      @fetch_path   = fetch_path
      @install_path = install_path
      @options      = options
    end
    
    def fetch
      
    end
    
    def install
      
    end
    
    def determine_name
      
    end
    
    def determine_version
      
    end
    
    def remote?
      fetch_path =~ /^http/
    end
    
    def tmp_path
      File.join(install_path, 'tmp')
    end
    
  end
end