module Jim
  class Bundler
    class MissingFile < Jim::Error; end
    
    attr_accessor :jimfile, :index, :paths
   
    def initialize(jimfile, index)
      @jimfile = jimfile.is_a?(Pathname) ? jimfile.read : jimfile
      @index = index
      @paths = []
    end
    
    def resolve!
      jimfile.each_line do |search|
        name, version = search.strip.split(/\s+/)
        path = index.find(name, version)
        if !path
          raise(MissingFile, 
          "Could not find #{name} #{version} in any of these paths #{index.directories.join(':')}")
        end
        @paths << path
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
      io << ::Closure::Compiler.new.compress(bundle!)
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
    
  end
end