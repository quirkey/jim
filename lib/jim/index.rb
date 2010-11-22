module Jim
  # Index managages a list of directories which are searched to find requirements
  class Index
    attr_reader :directories

    # Initialize an Index with a list of directories. The firse directory
    # is assumed to be the JIMHOME
    def initialize(*directories)
      @directories = [directories].flatten.compact
      @jimhome_re  = /#{Pathname.new(@directories.first).expand_path.to_s}/
    end

    # Add a directory to the index
    def add(directory)
      @directories.unshift directory
    end

    # List all available files in the directories or only those matching `search`.
    # Returns a sorted array of arrays.
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

    # Find a file in the index by `name` and an optional `version`.
    # If found, returns a `Pathname` where the file can be retrieved.
    def find(name, version = nil)
      name     = Pathname.new(name)
      stem     = name.basename
      version  = version && version.strip != '' ? version.strip : nil
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

    # Find _all_ paths matching `name` and `version`. Returning an array.
    def find_all(name, version = nil)
      matched = []
      find(name, version) {|p| matched << p }
      matched
    end

    # Is this path in the JIMHOME
    def in_jimhome?(path)
      !!(path.to_s =~ @jimhome_re)
    end

    # Iterate through every file in the index yielding the path to the block
    def each_file_in_index(ext, &block)
      Jim.each_path_in_directories(@directories, ext, [], &block)
    end

  end
end
