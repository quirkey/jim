module Jim
  class VersionParser

    NOT_EXTENSIONS = %w{.min .pre .beta}

    def self.parse_filename(filename)
      f = Pathname.new(filename).basename.to_s
      extension = f.scan(/\.[^\.\d\s\-\_][^\.]*$/)[0]
      if NOT_EXTENSIONS.include?(extension)
        extension = nil
      else 
        f.gsub!(/#{extension}$/, '')
      end 

      name, after_name, delimiter, version = f.scan(/^([a-z\.\-\_]+)(([\.\-\_\s])v?(([\w\d]{6,7})|(\d[\d\w\.]*)))?$/i)[0]
      [name || f, version || "0"]
    end

    def self.parse_package_json(package)
      json = Yajl::Parser.parse(package)
      [json["name"], json["version"]]
    end


  end
end