module Jim
  # Index managages a list of directories which are searched to find requirements
  class Index
    attr_reader :directories
    
    def initialize(*directories)
      @directories = directories.flatten
    end

    def add(directory)
      @directories.unshift directory
    end
    
    def list
      list = {}
      each_file_in_index('.js') do |filename|
        if /lib\/([^\/]+)-([\d\w\.\-]+)\/.+/.match filename
          name    = $1
          version = $2
        else
          name, version = Jim::VersionParser.parse_filename(filename)
        end
        if name && version
          list[name] ||= []
          list[name] << [version, filename]
        end
      end
      list.sort
    end

    def find(name, version = nil, first = true)
      name     = Pathname.new(name)
      stem     = name.basename
      ext      = '.js'
      possible_paths = if version
        [
          /#{stem}-#{version}\/#{name}#{ext}$/,
         /#{name}-#{version}#{ext}$/
        ]
      else
        [
          /#{name}#{ext}/,
          /#{name}-[\d\w\.\-]+#{ext}/
        ]
      end
      final = false
      each_file_in_index(ext) do |filename|
        possible_paths.each do |p|
          if File.file?(filename) && p.match(filename)
            final = Pathname.new(filename).expand_path
            break
          end
        end
        break if final
      end
      final
    end
    
    def each_file_in_index(ext, &block)
      @directories.each do |dir|
        Dir.glob(Pathname.new(dir) + '**' + "*#{ext}") do |filename|
          yield Pathname.new(filename)
        end
      end
    end

  end
end