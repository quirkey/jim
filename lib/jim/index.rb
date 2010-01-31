module Jim
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
        list[filename.stem] ||= []
        list[filename.stem] << filename.version
      end
      list
    end

    def find(name, version = nil)
      name     = Pathname.new(name)
      extname  = name.extname
      basename = name.stem
      ext      = (extname.nil? || extname.strip == '') ? '.js' : extname
      possible_paths = if version
        [
          /#{basename}\/#{version}\/#{name}#{ext}$/,
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
          if p.match filename
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
          yield filename
        end
      end
    end

  end
end