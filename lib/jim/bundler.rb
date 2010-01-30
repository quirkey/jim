module Jim
  class Bundler
    class MissingFile < Jim::Error; end
    
    attr_accessor :jimfile, :index, :requirements, :paths, :options 
   
    def initialize(jimfile, index, options = {})
      self.jimfile      = jimfile.is_a?(Pathname) ? jimfile.read : jimfile
      self.index        = index
      self.options      = {}
      self.requirements = []
      parse_jimfile
      self.options.merge(options)
      self.paths        = []
    end
    
    def resolve!
      self.requirements.each do |search|
        name, version = search.strip.split(/\s+/)
        path = index.find(name, version)
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
      io = io_for_path(to)
      paths.each do |path|
        io << path.read
      end
      io
    end
    
    def compress!(to = nil)
      io = io_for_path(to)
      io << ::Closure::Compiler.new(options[:compressor] || {}).compress(bundle!)
      io
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
        elsif line.strip != ''
          self.requirements << line
        end
      end
    end
    
  end
end