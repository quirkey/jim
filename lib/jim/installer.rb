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
      min
      \_([^\/]+)
      \.([^\/]+)
    }
    
    def self.tmp_root
      @tmp_root ||= Pathname.new('/tmp/jim')
    end
    
    def self.tmp_root=(new_tmp_root)
      @tmp_root = Pathname.new(new_tmp_root)
    end
        
    attr_reader :fetch_path, :install_path, :options, :fetched_path, :name, :version, :package_json

    def initialize(fetch_path, install_path, options = {})
      @fetch_path   = Pathname.new(fetch_path)
      @install_path = Pathname.new(install_path)
      @options      = options
    end

    def fetch
      logger.info "fetching #{fetch_path}"
      @fetched_path = Downlow.get(fetch_path, tmp_path, :tmp_dir => tmp_root)
      logger.debug "fetched #{@fetched_path}"
      @fetched_path
    end

    def install
      fetch
      parse_package_json
      determine_name_and_version
      logger.info "installing #{name} #{version}"
      logger.debug "fetched_path #{@fetched_path}"
      if options[:shallow]
        shallow_filename = [name, (version == "0" ? nil : version)].compact.join('-')
        final_path = install_path + "#{shallow_filename}#{fetched_path.extname}"
      else
        final_path = install_path + 'lib' + "#{name}-#{version}" + "#{name}.js"
      end
      if @fetched_path.directory?
        # install every js file
        installed_paths = []
        sub_options = options.merge({
          :name => nil, 
          :version => nil,
          :parent_version => version, 
          :package_json => package_json.merge("name" => nil)
        })
        Jim.each_path_in_directories([@fetched_path], '.js', IGNORE_DIRS) do |subfile|
          logger.info "found file #{subfile}"
          installed_paths << Jim::Installer.new(subfile, install_path, sub_options).install
        end
        logger.info "Extracted to #{install_path}, #{installed_paths.length} file(s)"
        return installed_paths
      end
      logger.debug "installing to #{final_path}"
      if final_path.exist? 
        logger.debug "#{final_path} already exists"
        if options[:force]
          FileUtils.rm_rf(final_path)
        elsif Digest::MD5.hexdigest(File.read(final_path)) == Digest::MD5.hexdigest(File.read(@fetched_path))
          logger.info "duplicate file, skipping"
          return final_path
        else
          raise(Jim::FileExists.new(final_path))
        end
      end
      Downlow.extract(@fetched_path, :destination => final_path, :tmp_dir => tmp_root)
      # install json
      install_package_json(final_path.dirname + 'package.json') if !options[:shallow]
      installed = final_path.directory? ? Dir.glob(final_path + '**/*').length : 1
      logger.info "Extracted to #{final_path}, #{installed} file(s)"
      final_path
    ensure
      FileUtils.rm_rf(@fetched_path) if @fetched_path && @fetched_path.exist?
      final_path
    end

    def determine_name_and_version
      (name && version) ||
      name_and_version_from_options ||
      name_and_version_from_comments ||
      name_and_version_from_package_json ||
      name_and_version_from_filename
      @version = (version == "0" && options[:parent_version]) ? options[:parent_version] : version
    end

    private
    def tmp_root
      @tmp_root ||= make_tmp_root 
    end

    def tmp_dir
      @tmp_dir ||= make_tmp_dir
    end

    def tmp_path
      tmp_dir + fetch_path.basename
    end

    def logger
      Jim.logger
    end
    
    def make_tmp_root
      self.class.tmp_root + (Time.now.to_i + rand(10000)).to_s
    end
    
    def make_tmp_dir
      dir = tmp_root + fetch_path.stem
      dir.mkpath
      dir
    end
    
    def parse_package_json
      @package_json = @options[:package_json] || {}
      package_json_path = if fetched_path.directory?
        fetched_path + 'package.json'
      elsif options[:shallow] && fetch_path.file?
        fetch_path.dirname + 'package.json'
      else
        fetched_path.dirname + 'package.json'
      end
      logger.debug "package.json path: #{package_json_path}"
      if package_json_path.readable?
        @package_json = Yajl::Parser.parse(package_json_path.read)
      end
    end

    def install_package_json(to_path, options = {})
      hash = @package_json.merge({
        "name" =>  name, 
        "version" => version,
        "install" => {
          "at" => Time.now.httpdate,
          "from" => fetch_path,
          "with" => "jim #{Jim::VERSION}"
        }
      }).merge(options)
      Pathname.new(to_path).open('w') do |f|
        Yajl::Encoder.encode(hash, f, :pretty => true)
      end
    end

    def name_and_version_from_options
      @name = options[:name] if options[:name] && !name
      @version = options[:version] if options[:version] && !version
      logger.debug "name and version from options: #{name} #{version}"
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
      logger.debug "name and version from comments: #{name} #{version}"
      name && version
    end

    def name_and_version_from_package_json
      parse_package_json if !@package_json
      sname, sversion = @package_json['name'], @package_json['version']
      @name ||= sname
      @version ||= sversion
      logger.debug "name and version from package.json: #{name} #{version}"
      name && version
    end

    def name_and_version_from_filename
      fname, fversion = VersionParser.parse_filename(fetched_path.basename.to_s)
      @name ||= fname
      @version ||= fversion
      logger.debug "name and version from filename: #{name} #{version}"
      name && version
    end

  end
end