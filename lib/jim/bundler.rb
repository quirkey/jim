module Jim
  # Bundler takes parses a Jimfile that specifies requirements as names and
  # versions and then can bundle, compress, or copy those files into specific dirs
  # or files.
  #
  # A Jimfile has a really simple format:
  #
  #     // comments look like JS comments
  #     // you can set options by adding comments that look like JSON pairs
  #     // bundle_path: /path/to/bundle.js
  #
  #     // A requirement is just a name and an optional version
  #     // requirements are resolved and bundled in order of specification
  #     jquery 1.4.2
  #     jquery.color
  #     sammy 0.5.0
  #
  #
  class Bundler
    class MissingFile < Jim::Error; end
    class InvalidBundle < Jim::Error; end

    attr_accessor :jimfile, :index, :bundles, :paths, :options
    attr_reader :jimfile, :bundle_dir

    # create a new bundler instance passing in the Jimfile as a `Pathname` or a
    # string. `index` is a Jim::Index
    def initialize(jimfile, index = nil, extra_options = {})
      self.index        = index || Jim::Index.new
      self.options      = {
        :compressed_suffix => '.min'
      }
      self.bundles      = {}
      self.jimfile      = jimfile
      self.options = options.merge(extra_options)
      self.paths        = {}
      if options[:vendor_dir]
        logger.debug "adding vendor dir to index #{options[:vendor_dir]}"
        self.index.add(options[:vendor_dir])
      end
    end

    def jimfile=(file)
      @jimfile = file.is_a?(Pathname) ? file.read : file
      # look for old jimfile
      if @jimfile =~ /^\/\//
        logger.warn "You're Jimfile is in a deprecated format. Run `jim update_jimfile` to convert it."
        parse_old_jimfile
      else
        parse_jimfile
      end
      @jimfile
    end

    def bundle_dir=(new_dir)
      if new_dir
        new_dir = Pathname.new(new_dir)
        new_dir.mkpath
      end
      @bundle_dir = new_dir
    end

    def jimfile_to_json
      h = {
        "bundle_dir" => bundle_dir
      }.merge(options)
      h['bundles'] = self.bundles
      Yajl::Encoder.encode(h, :pretty => true)
    end

    # resove the requirements specified into Jimfile or raise a MissingFile error
    def resolve!
      self.bundles.each do |bundle_name, requirements|
        self.paths[bundle_name] = []
        requirements.each do |name, version|
          path = self.index.find(name, version)
          if !path
            raise(MissingFile,
            "Could not find #{name} #{version} in any of these paths #{index.directories.join(':')}")
          end
          self.paths[bundle_name] << [path, name, version]
        end
      end
      paths
    end

    # concatenate all of the bundles to the dir set in the `bundle_dir` option
    # or a specific bundle specified by bundle name. Setting `compress` to
    # true will run the output of each bundle to the Google Closure Compiler.
    # You can also use the YUI compressor by setting the option :compressor to 'yui'
    # Raises an error if there is no bundled dir or specific bundle set
    def bundle!(bundle_name = false, compress = false)
      resolve! if paths.empty?
      if bundle_name
        files = self.paths[bundle_name]
        if bundle_dir
          path = path_for_bundle(bundle_name, compress)
          concatenate(files, path, compress)
          [path]
        else
          concatenate(files, "", compress)
        end
      elsif bundle_dir
        self.paths.collect do |bundle_name, files|
          path = path_for_bundle(bundle_name, compress)
          concatenate(files, path, compress)
          path
        end
      else
        raise(InvalidBundle,
          "Must set either a :bundle_dir to write files to or a specific bundle to write to STDOUT")
      end
    end

    # Alias to running `bundle!` with compress = true
    def compress!(bundle_name = false)
      bundle!(bundle_name, true)
    end

    # copy each of the requirements into the dir specified with `dir` or the path
    # specified with the :vendor_dir option. Returns the dir it was vendored to.
    def vendor!(dir = nil, force = false)
      resolve! if paths.empty?
      dir ||= options[:vendor_dir]
      dir ||= 'vendor' # default
      logger.debug "Vendoring #{paths.length} files to #{dir}"
      paths.collect {|n, p| p }.flatten.each do |path, name, version|
        if index.in_jimhome?(path)
          Jim::Installer.new(path, dir, :shallow => true, :force => force).install
        end
      end
      dir
    end

    def bundle_paths
      self.bundles.collect {|name, reqs|  path_for_bundle(name) }
    end

    # Run the uncompressed js through a JS compressor (closure-compiler) by
    # default. Setting options[:compressor] == 'yui' will force the YUI JS Compressor
    def compress_js(uncompressed)
      if options[:compressor] == 'yui'
        begin
          require "yui/compressor"
        rescue LoadError
          raise "You must install the yui compressor gem to use the compressor\ngem install yui-compressor"
        end
        compressor = ::YUI::JavaScriptCompressor.new
      else
        begin
          require 'closure-compiler'
        rescue LoadError
          raise "You must install the closure compiler gem to use the compressor\ngem install closure-compiler"
        end
        compressor = ::Closure::Compiler.new
      end
      begin
        compressor.compress(uncompressed)
      rescue Exception => e
        logger.error e.message
      end
    end

    private
    def concatenate(paths, io, compress)
      if io.is_a?(Pathname)
        io = io.open('w')
        logger.debug "#{compress ? 'Compressing' : 'Bundling'} to #{io}"
      end
      final_io, io = io, "" if compress
      paths.each do |path, name, version|
        io << path.read << "\n"
      end
      if compress
        final_io << compress_js(io)
        io = final_io
      end
      io.close if io.respond_to?(:close)
      io
    end

    def path_for_bundle(bundle_name, compressed = false)
      bundle_dir + "#{bundle_name}#{compressed ? options[:compressed_suffix] : ''}.js"
    end

    def parse_jimfile
      json = Yajl::Parser.parse(jimfile)
      json.each do |k, v|
        set_option(k, v)
      end
    end

    def parse_old_jimfile
      bundle = []
      jimfile.each_line do |line|
        if /^\/\/\s?([^\:]+)\:\s(.*)$/.match line
          k, v = $1, $2.strip
          if k == 'bundled_path'
            k, v = 'bundle_dir', File.dirname(v)
          end
          set_option(k, v)
        elsif line !~ /^\// && line.strip != ''
          bundle << line.split(/\s+/, 2).compact.collect {|s| s.strip }.reject {|s| s == '' }
        end
      end
      self.bundles['default'] = bundle
    end

    def set_option(k, v)
      if respond_to?("#{k}=")
        self.send("#{k}=", v)
      else
        self.options[k.to_sym] = v
      end
    end

    def logger
      Jim.logger
    end

  end
end
