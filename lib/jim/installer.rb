module Jim
  class Installer
    attr_reader :fetch_path, :install_path, :options, 
                :fetched_path, :name, :version
    
    def initialize(fetch_path, install_path, options = {})
      @fetch_path   = Pathname.new(fetch_path)
      @install_path = Pathname.new(install_path)
      @options      = options
    end
    
    def fetch
      logger.info "fetching #{fetch_path}"
      @fetched_path = Downlow.fetch(fetch_path, :destination => tmp_path)
      logger.debug "fetched #{@fetched_path}"
      @fetched_path
    end
    
    def install
      fetch
      determine_name if !name
      determine_version if !version
      logger.info "installing #{name} #{version}"
      logger.debug "fetched_path #{@fetched_path}"
      if options[:shallow]
        final_path = install_path + "#{name}#{fetched_path.extname}"
      else
        final_dir = install_path + 'lib' + "#{name}-#{version}"
        final_path = (fetched_path.to_s =~ /\.js$/) ? 
          final_dir + "#{name}.js" : 
          final_dir
      end
      logger.debug "installing to #{final_path}"
      if final_path.exist? 
        logger.debug "#{final_path} already exists"
        options[:force] ? FileUtils.rm_rf(final_path) : raise(Jim::FileExists.new(final_path))
      end
      Downlow.extract(@fetched_path, :destination => final_path)
      installed = final_path.directory? ? Dir.glob(final_path + '**/*').length : 1
      logger.info "Extracted to #{final_path}, #{installed} file(s)"
    ensure
      FileUtils.rm_rf(fetched_path) if fetched_path.exist?
      return final_path
    end
    
    def determine_name
      return @name = options[:name] if options[:name]
      if fetched_path.file?
        # try to read and determine name
        fetched_path.each_line do |line|
          if /(\*|\/\/)\s+name:\s+([\d\w\.\-]+)/i.match line
            return @name = $2
          end
        end
      end
      @name = fetched_path.stem.gsub(/(\-[^\-]+)$/, '')
    end
    
    def determine_version
      return @version = options[:version] if options[:version]
      if fetched_path.file?
        # try to read and determine version
        fetched_path.each_line do |line|
          if /(\*|\/\/)\s+version:\s+([\d\w\.\-]+)/i.match line
            return @version = $2
          end
        end
      end
      @version = fetched_path.version || '0'
    end
            
    private
    def tmp_root
      @tmp_root ||= Pathname.new('tmp')
    end
    
    def tmp_dir
      dir = tmp_root + fetch_path.stem
      dir.mkpath
      dir
    end
    
    def tmp_path
      tmp_dir + fetch_path.basename
    end
      
    def logger
      Jim.logger
    end
  end
end