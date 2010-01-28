module Jim
  class Installer
    attr_reader :fetch_path, :install_path, :options, 
                :name, :version
    
    def initialize(fetch_path, install_path, options = {})
      @fetch_path   = Pathname.new(fetch_path)
      @install_path = Pathname.new(install_path)
      @options      = options
    end
    
    def run
      fetch
      install
    end
    
    def fetch
      tmp_file = File.open(tmp_path, 'w')
      if remote?
        open(fetch_path.to_s) {|f| tmp_file << f.read }
      else
        File.open(fetch_path) {|f| tmp_file << f.read }
      end
      tmp_file.close
      tmp_path
    end
    
    def install
      determine_name
      determine_version
      final_dir = install_path + name + version
      final_dir.mkpath
      tmp_path.cp final_dir + "#{name}#{tmp_path.extname}"
    end
    
    def determine_name
      return @name = options[:name] if options[:name]
      if tmp_path.file?
        # try to read and determine name
        tmp_path.each_line do |line|
          if /(\*|\/\/)\s+name:\s+([\d\w\.\-]+)/i.match line
            return @name = $2
          end
        end
      end
      @name = tmp_path.stem.gsub(/(\-[\d\w\.]+)$/, '')
    end
    
    def determine_version
      return @version = options[:version] if options[:version]
      if tmp_path.file?
        # try to read and determine version
        tmp_path.each_line do |line|
          if /(\*|\/\/)\s+version:\s+([\d\w\.\-]+)/i.match line
            return @version = $2
          end
        end
      end
      @version = tmp_path.version
    end
    
    def remote?
      fetch_path.to_s =~ /^http/
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