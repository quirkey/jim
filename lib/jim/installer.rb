module Jim
  class Installer
    attr_reader :fetch_path, :install_path, :options, 
                :name, :version
    
    def initialize(fetch_path, install_path, options = {})
      @fetch_path   = Pathname.new(fetch_path)
      @install_path = Pathname.new(install_path)
      @options      = options
    end
    
    def fetch
      tmp_file = File.open(tmp_path, 'w')
      if remote?
        open(fetch_path) {|f| tmp_file << f.read }
      else
        File.open(fetch_path) {|f| tmp_file << f.read }
      end
      tmp_file.close
      tmp_path
    end
    
    def install
      
    end
    
    def determine_name
      @name = options[:name] and return if options[:name]
      @name = tmp_path.stem
    end
    
    def determine_version
      @version = options[:version] and return if options[:version]
      @version = tmp_path.version
    end
    
    def remote?
      fetch_path =~ /^http/
    end
        
    private
    def tmp_root
      install_path + 'tmp'
    end
    
    def tmp_dir
      dir = Pathname.new(File.join(tmp_root, fetch_path.stem))
      dir.mkpath
      dir
    end
    
    def tmp_path
      Pathname.new(tmp_dir) + fetch_path.basename
    end
      
  end
end