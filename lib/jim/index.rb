module Jim
  # Index managages a list of directories which are searched to find requirements
  class Index
    attr_reader :directories
    
    def initialize(*directories)
      @directories = [directories].flatten.compact
      @jimhome_re  = /#{Pathname.new(@directories.first).expand_path.to_s}/
    end

    def add(directory)
      @directories.unshift directory
    end
    
    def list(search = nil)
      list = {}
      each_file_in_index('.js') do |filename|
        if /lib\/([^\/\-]+)-([\d\w\.\-]+)\/.+/.match filename
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
      if search
        search = /#{search}/i
        list = list.find_all {|lib| lib[0] =~ search }
      end
      list.sort
    end

    def find(name, version = nil)
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
            block_given? ? yield(final) : break
          end
        end
        break if final && !block_given?
      end
      final
    end
    
    def in_jimhome?(path)
      path.to_s =~ @jimhome_re
    end
    
    def find_all(name, version = nil)
      matched = []
      find(name, version) {|p| matched << p }
      matched
    end
    
    def each_file_in_index(ext, &block)
      Jim.each_path_in_directories(@directories, ext, [], &block)
    end

  end
end