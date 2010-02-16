module Jim
  class VersionParser

    NOT_EXTENSIONS = %w{.min .pre .beta}

    def self.parse_filename(filename)
      f = filename.dup
      extension = f.scan(/\.[^\.\d\s\-\_][^\.]*$/)[0]
      if NOT_EXTENSIONS.include?(extension)
        extension = nil
      else 
        f.gsub!(/#{extension}$/, '')
      end 

      name, delimiter, version = f.scan(/^([a-z\.\-]+)([\.\-\_\s])(([\w\d]{6,7})|([\d\w\.]+))$/i)[0]

      [name, version]
    end

    def self.parse_package_json(package)
      json = Yajl::Parser.parse(package)
      [json["name"], json["version"]]
    end


  end
end