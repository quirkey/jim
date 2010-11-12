require 'thor'
require 'thor/actions'


module Jim

  # CLI handles the command line interface for the `jim` binary.
  # The layout is farily simple. Options are parsed using optparse.rb and
  # the different public methods represent 1-1 the commands provided by the bin.
  class CLI < ::Thor
    include Thor::Actions

    attr_accessor :jimfile, :jimhome, :debug , :force, :stdout

    class_option "jimhome",
        :type => :string,
        # :aliases => '-d',
        :banner => "set the install path/JIMHOME dir (default ~/.jim)"

    class_option "jimfile",
        :type => :string,
        :aliases => '-j',
        :banner => "load specific Jimfile at path (default ./Jimfile)"

    class_option "force",
        :default => false,
        :aliases => '-f',
        :banner => "force file creation/overwrite"

    class_option "debug",
        :default => false,
        :aliases => '-d',
        :banner => "set log level to debug"

    class_option "version",
        :type => :boolean,
        :aliases => '-v',
        :banner => "print version and exit"

    # create a new instance with the args passed from the command line i.e. ARGV
    def initialize(*)
      super
      if options[:version]
        say "jim #{Jim::VERSION}", :red
        exit
      end
      @output = ""
      # set the default jimhome
      self.jimhome = Pathname.new(ENV['JIMHOME'] || '~/.jim').expand_path
      # parse the options
      self.jimfile = Pathname.new(options[:jimfile] || 'Jimfile').expand_path
      self.force = options[:force]
      self.debug = options[:debug]
      logger.level = Logger::DEBUG if debug
    end

    # def commands
    #   logger.info "Usage: jim [options] [command] [args]\n"
    #   logger.info "Commands:"
    #   logger.info template('commands')
    # end
    #
    # # list the possible commands without detailed descriptions
    # def cheat
    #   logger.info "Usage: jim [options] [command] [args]\n"
    #   logger.info "Commands:"
    #   logger.info [*template('commands')].grep(/^\w/).join
    #   logger.info "run commands for details"
    # end
    # alias :help :cheat

    desc 'init [APPDIR]', 'Create an example Jimfile at path or the current directory if path is omitted'
    def init(dir = nil)
      dir = Pathname.new(dir || '')
      jimfile_path = dir + 'Jimfile'
      if jimfile_path.readable? && !force
        raise Jim::FileExists.new(jimfile_path)
      else
        File.open(jimfile_path, 'w') do |f|
          f << template('jimfile')
        end
        logger.info "wrote Jimfile to #{jimfile_path}"
      end
    end

    desc 'install <URL> [NAME] [VERSION]',
      "Install the file(s) at url into the JIMHOME directory."

    long_desc <<-EOT
Install the file(s) at url into the JIMHOME directory. URL can be any path
or url that Downlow understands. This means:

  jim install http://code.jquery.com/jquery-1.4.1.js
  jim install ../sammy/
  jim install gh://quirkey/sammy
  jim install git://github.com/jquery/jquery.git
    EOT
    def install(url, name = false, version = false)
      Jim::Installer.new(url, jimhome, :force => force, :name => name, :version => version).install
    end

    desc 'bundle [BUNDLED_PATH]',
      "Bundle all the files listed in a Jimfile and save them to [BUNDLED_PATH]."
    long_desc <<-EOT
      Bundle all the files listed in a Jimfile and save them to [BUNDLED_PATH].
      If the bundled_path is not set, jim will try to use the bundled_path set in
      the Jimfile. If no bundled_path is found - it will output the entire bundle
      to STDOUT.
      If no Jimfile is set in the options, assumes ./Jimfile.
    EOT
    def bundle(to = nil)
      to = STDOUT if stdout
      io = bundler.bundle!(to)
      logger.info "Wrote #{File.size(io.path) / 1024}kb" if io.respond_to? :path
    end

    desc "compress [COMPRESSED_PATH]",
      "Bundle all the files listed in a Jimfile, run through the google closure compiler and save them to [COMPRESSED_PATH]."
    long_desc <<-EOT
      Bundle all the files listed in a Jimfile, run through the google closure
      compiler and save them to [compressed_path].
      If the compressed_path is not set, jim will try to use the compressed_path
      set in the Jimfile. If no compressed_path is found - it will output the
      entire compressed bundle to STDOUT.
      If no Jimfile is set in the options, assumes ./Jimfile.
    EOT
    def compress(to = nil)
      to = STDOUT if stdout
      io = bundler.compress!(to)
      logger.info "Wrote #{File.size(io.path) / 1024}kb" if io.respond_to? :path
    end

    desc "vendor [VENDOR_DIR]", "Copy all the files listed in Jimfile to the vendor_dir"
    def vendor(dir = nil)
      bundler.vendor!(dir, force)
    end

    desc "list [SEARCH]", "List all the installed packages and their versions, optionally limiting by [SEARCH]"
    def list(search = nil)
      logger.info "Getting list of installed files in\n#{installed_index.directories.join(':')}"
      logger.info "Searching for '#{search}'" if search
      list = installed_index.list(search)
      logger.info "Installed:"
      print_version_list(list)
    end
    map "installed" => "list"

    desc "available [SEARCH]" ,"List all available projects and versions including those in the local path, or paths specified in a Jimfile"
    def available(search = nil)
      logger.info "Getting list of all available files in\n#{index.directories.join("\n")}"
      logger.info "Searching for '#{search}'" if search
      list = index.list(search)
      logger.info "Available:"
      print_version_list(list)
    end

    desc "remove <NAME> [VERSION]", "Iterate through the install files and prompt for the removal of those matching the supplied NAME and VERSION"
    def remove(name, version = nil)
      logger.info "Looking for files matching #{name} #{version}"
      files = installed_index.find_all(name, version)
      if files.length > 0
        logger.info "Found #{files.length} matching files"
        removed = 0
        files.each do |filename|
          response = Readline.readline("Remove #{filename}? (y/n)\n")
          if response.strip =~ /y/i
            logger.info "Removing #{filename}"
            filename.delete
            removed += 1
          else
            logger.info "Skipping #{filename}"
          end
        end
        logger.info "Removed #{removed} files."
      else
        logger.info "No installed files matched."
      end
    end
    map "uninstall" => "remove"

    desc "resolve", "Resolve all the paths listed in a Jimfile and print them to STDOUT. If no Jimfile is set in the options, assumes ./Jimfile."
    def resolve
      resolved = bundler.resolve!
      logger.info "Files:"
      resolved.each do |r|
        logger.info r.join(" | ")
      end
      resolved
    end

    desc "pack [DIR]", "Runs in order, vendor, bundle, compress. This command simplifies the common workflow of vendoring and re-bundling before committing or deploying changes to a project"
    def pack(dir = nil)
      logger.info "packing the Jimfile for this project"
      vendor(dir)
      bundle
      compress
    end

    private
    def index
      @index ||= Jim::Index.new(install_dir, Dir.pwd)
    end

    def installed_index
      @installed_index ||= Jim::Index.new(install_dir)
    end

    def bundler
      @bundler ||= Jim::Bundler.new(jimfile, index)
    end

    def install_dir
      jimhome + 'lib'
    end

    def template(path)
      (Pathname.new(__FILE__).dirname + 'templates' + path).read
    end

    def logger
      Jim.logger
    end

    def print_version_list(list)
      list.each do |file, versions|
        logger.info "#{file} (#{VersionSorter.rsort(versions.collect {|v| v[0] }).join(', ')})"
      end
    end

  end
end
