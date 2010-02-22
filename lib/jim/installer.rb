module Jim
  class Installer
    
    IGNORE_DIRS = %w{
      vendor
      external
      test
      tests
      unit
      site
      examples
      demo
      \_([^\/]+)
      \.([^\/]+)
    }
    
    def self.tmp_root
      @tmp_root ||= Pathname.new('/tmp/jim')
    end
    
    def self.tmp_root=(new_tmp_root)
      @tmp_root = Pathname.new(new_tmp_root)
    end
        
    attr_reader :fetch_path, :install_path, :options, :fetched_path, :name, :version

    def initialize(fetch_path, install_path, options = {})
      @fetch_path   = Pathname.new(fetch_path)
      @install_path = Pathname.new(install_path)
      @options      = options
    end

    def fetch
      logger.info "fetching #{fetch_path}"
      @fetched_path = Downlow.get(fetch_path, tmp_path)
      logger.debug "fetched #{@fetched_path}"
      @fetched_path
    end

    def install
      fetch
      determine_name_and_version
      logger.info "installing #{name} #{version}"
      logger.debug "fetched_path #{@fetched_path}"
      if options[:shallow]
        final_path = install_path + "#{name}.#{fetched_path.extname}"
      else
        final_dir = install_path + 'lib' + "#{name}-#{version}"
        final_path = (fetched_path.to_s =~ /\.js$/) ? final_dir + "#{name}.js" : final_dir
      end
      if @fetched_path.directory?
        # install every js file
        installed_paths = []
        sub_options = options.merge({:name => nil, :version => nil})
        Jim.each_path_in_directories([@fetched_path], '.js', IGNORE_DIRS) do |subfile|
          logger.info "found file #{subfile}"
          installed_paths << Jim::Installer.new(subfile, install_path, sub_options).install
        end
        return installed_paths
      end
      logger.debug "installing to #{final_path}"
      if final_path.exist? 
        logger.debug "#{final_path} already exists"
        options[:force] ? FileUtils.rm_rf(final_path) : raise(Jim::FileExists.new(final_path))
      end
      Downlow.extract(@fetched_path, :destination => final_path)
      installed = final_path.directory? ? Dir.glob(final_path + '**/*').length : 1
      logger.info "Extracted to #{final_path}, #{installed} file(s)"
      final_path
    ensure
      FileUtils.rm_rf(fetched_path) if fetched_path.exist?
      final_path
    end

    def determine_name_and_version
      (name && version) ||
      name_and_version_from_options ||
      name_and_version_from_comments ||
      name_and_version_from_package_json ||
      name_and_version_from_filename
      @version ||= '0'
    end

    private
    def tmp_root
      self.class.tmp_root
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

    def name_and_version_from_options
      @name = options[:name] if options[:name] && !name
      @version = options[:version] if options[:version] && !version
      name && version
    end

    def name_and_version_from_comments
      if fetched_path.file?
        # try to read and determine name
        fetched_path.each_line do |line|
          if !name && /(\*|\/\/)\s+name:\s+([\d\w\.\-]+)/i.match(line)
            @name = $2
          end

          if !version && /(\*|\/\/)\s+version:\s+([\d\w\.\-]+)/i.match(line)
            @version = $2
          end
        end
      end
      name && version
    end

    def name_and_version_from_package_json
      if !fetched_path.file? && (fetched_path + 'package.json').readable?
        sname, sversion = VersionParser.parse_package_json((fetched_path + "package.json").read)
        @name ||= sname
        @version ||= sversion
      end
      name && version
    end

    def name_and_version_from_filename
      fname, fversion = VersionParser.parse_filename(fetched_path.basename.to_s)
      @name ||= fname
      @version ||= fversion
      name && version
    end

  end
end