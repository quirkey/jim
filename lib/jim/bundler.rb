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

    attr_accessor :jimfile, :index, :requirements, :paths, :options 
    
    # create a new bundler instance passing in the Jimfile as a `Pathname` or a
    # string. `index` is a Jim::Index
    def initialize(jimfile, index = nil, options = {})
      self.jimfile      = jimfile.is_a?(Pathname) ? jimfile.read : jimfile
      self.index        = index || Jim::Index.new
      self.options      = {}
      self.requirements = []
      parse_jimfile
      self.options.merge(options)
      self.add(options[:vendor_dir]) if options[:vendor_dir]
      self.paths        = []
    end

    # resove the requirements specified into Jimfile or raise a MissingFile error
    def resolve!
      self.requirements.each do |search|
        name, version = search.strip.split(/\s+/)
        path = self.index.find(name, version)
        if !path
          raise(MissingFile, 
          "Could not find #{name} #{version} in any of these paths #{index.directories.join(':')}")
        end
        self.paths << path
      end
      paths
    end

    # concatenate all the requirements into a single file and write to `to` or to the
    # path specified in the :bundled_path option
    def bundle!(to = nil)
      resolve! if paths.empty?
      to = options[:bundled_path] if to.nil? && options[:bundled_path]
      io = io_for_path(to)
      logger.info "bundling to #{to}" if to
      paths.each do |path|
        io << path.read << "\n"
      end
      io
    end

    # concatenate all the requirements into a single file then run through a JS 
    # then write to `to` or to the path specified in the :bundled_path option.
    # You can also use the YUI compressor by setting the option :compressor to 'yui'
    def compress!(to = nil)
      to = options[:compressed_path] if to.nil? && options[:compressed_path]
      io = io_for_path(to)
      logger.info "compressing to #{to}"
      io << compress_js(bundle!(false))
      io
    end

    # copy each of the requirements into the dir specified with `dir` or the path
    # specified with the :vendor_dir option
    def vendor!(dir = nil)
      resolve! if paths.empty?
      dir ||= options[:vendor_dir]
      dir ||= 'vendor' # default
      logger.info "vendoring to #{dir}"
      paths.each do |path|
        Jim::Installer.new(path, dir, :shallow => true).install
      end
    end

    # Run the uncompressed test through a JS compressor (closure-compiler) by
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
      compressor.compress(uncompressed)
    end

    private
    def io_for_path(to)
      case to
      when IO
        to
      when Pathname
        to.dirname.mkpath
        to.open('w')
      when String
        to = Pathname.new(to)
        io_for_path(to)
      else
        ""
      end
    end

    def parse_jimfile
      jimfile.each_line do |line|
        if /^\/\/\s?([^\:]+)\:\s(.*)$/.match line
          self.options[$1.to_sym] = $2.strip
        elsif line !~ /^\// && line.strip != ''
          self.requirements << line
        end
      end
    end
    
    def logger
      Jim.logger
    end

  end
end