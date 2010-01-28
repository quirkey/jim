module Jim
  class Installer
    attr_reader :fetch_path, :install_path, :options
    
    def initialize(fetch_path, install_path, options = {})
      @fetch_path   = fetch_path
      @install_path = install_path
      @options      = options
    end
    
    def fetch
      tmp_file = File.open(File.join(tmp_dir, filename), 'w')
      if remote?
        open(fetch_path) {|f| tmp_file << f.read }
      else
        File.open(fetch_path) {|f| tmp_file << f.read }
      end
      tmp_file.close
      true
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
    
    def tmp_dir
      dir = File.join(tmp_path, File.basename(fetch_path, File.extname(fetch_path)))
      FileUtils.mkdir_p(dir)
      dir
    end
    
    def filename
      @filename ||= File.basename(fetch_path)
    end
    
  end
end