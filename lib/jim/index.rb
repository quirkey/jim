module Jim
  class Index
    attr_reader :directories
    
    def initialize(*directories)
      @directories = directories.flatten
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
      @directories.each do |dir|
        Dir.glob(Pathname.new(dir) + '**' + "*#{ext}") do |filename|
          possible_paths.each do |p|
            if p.match filename
              return Pathname.new(filename).expand_path
            end
          end
        end
      end
      false
    end

  end
end