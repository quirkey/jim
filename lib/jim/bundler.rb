module Jim
  class Bundler
    class MissingFile < Jim::Error; end

    attr_accessor :jimfile, :index, :requirements, :paths, :options 

    def initialize(jimfile, index, options = {})
      self.jimfile      = jimfile.is_a?(Pathname) ? jimfile.read : jimfile
      self.index        = index || Jim::Index.new
      self.options      = {}
      self.requirements = []
      parse_jimfile
      self.options.merge(options)
      self.add(options[:vendor_dir]) if options[:vendor_dir]
      self.paths        = []
    end

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

    def compress!(to = nil)
      to = options[:compressed_path] if to.nil? && options[:compressed_path]
      io = io_for_path(to)
      logger.info "compressing to #{to}"
      io << js_compress(bundle!(false))
      io
    end

    def vendor!(dir = nil)
      resolve! if paths.empty?
      dir ||= options[:vendor_dir]
      dir ||= 'vendor' # default
      logger.info "vendoring to #{dir}"
      paths.each do |path|
        Jim::Installer.new(path, dir, :shallow => true).install
      end
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

    def js_compress(uncompressed)
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

    def logger
      Jim.logger
    end

  end
end