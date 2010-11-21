require 'thor'
require 'fssm'

module Jim

  # CLI handles the command line interface for the `jim` binary.
  # The layout is farily simple. Options are parsed using optparse.rb and
  # the different public methods represent 1-1 the commands provided by the bin.
  class CLI < ::Thor
    include Thor::Actions

    attr_accessor :jimfile, :jimhome, :debug , :force

    source_root File.dirname(__FILE__) + '/templates'

    class_option "jimhome",
        :type => :string,
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
      # set the default jimhome
      self.jimhome = Pathname.new(options[:jimhome] || ENV['JIMHOME'] || '~/.jim').expand_path
      # parse the options
      self.jimfile = Pathname.new(options[:jimfile] || 'Jimfile').expand_path
      self.force = options[:force]
      self.debug = options[:debug]
      logger.level = Logger::DEBUG if debug
    end

    desc 'init [APPDIR]',
      'Create an example Jimfile at path or the current directory if path is omitted'
    def init(dir = nil)
      dir = Pathname.new(dir || '')
      jimfile_path = dir + 'Jimfile'
      template('jimfile', jimfile_path)
    end

    desc 'install <URL> [NAME] [VERSION]',
      "Install the file(s) at url into the JIMHOME directory."

    long_desc <<-EOT
      Install the file(s) at url into the JIMHOME directory. URL can be any path
      or url that Downlow understands. This means:

        jim install http://code.jquery.com/jquery-1.4.1.js\n
        jim install ../sammy/\n
        jim install gh://quirkey/sammy\n
        jim install git://github.com/jquery/jquery.git\n
    EOT
    def install(url, name = false, version = false)
      Jim::Installer.new(url, jimhome, :force => force, :name => name, :version => version).install
    end

    desc 'bundle [BUNDLE_NAME]',
      "Bundle the files specified in Jimfile"
    long_desc <<-EOT
      Bundle all the files listed in a Jimfile and save them to [BUNDLED_PATH].
      If the bundled_path is not set, jim will try to use the bundled_path set in
      the Jimfile. If no bundled_path is found - it will output the entire bundle
      to STDOUT.

      If no Jimfile is set in the options, assumes ./Jimfile.
    EOT
    method_option "bundle_dir",
                  :type => :string,
                  :banner => "override the bundle_dir set in the Jimfile"
    method_option "stdout",
                  :default => false,
                  :aliases => '-o',
                  :type => :boolean,
                  :banner => "write the bundle to STDOUT"
    def bundle(bundle_name = nil)
      make_bundle(bundle_name, false)
    end

    desc "compress [COMPRESSED_PATH]",
      "Bundle all the files listed in a Jimfile, run through the google closure " +
      "compiler and save them to [COMPRESSED_PATH]."
    long_desc <<-EOT
      Bundle all the files listed in a Jimfile, run through the google closure
      compiler and save them to [compressed_path].

      If the compressed_path is not set, jim will try to use the compressed_path
      set in the Jimfile. If no compressed_path is found - it will output the
      entire compressed bundle to STDOUT.

      If no Jimfile is set in the options, assumes ./Jimfile.
    EOT
    method_option "bundle_dir",
                  :type => :string,
                  :banner => "override the bundle_dir set in the Jimfile"
    method_option "stdout",
                  :default => false,
                  :aliases => '-o',
                  :type => :boolean,
                  :banner => "write the bundle to STDOUT"
    def compress(bundle_name = nil)
      make_bundle(bundle_name, true)
    end

    desc "vendor [VENDOR_DIR]",
      "Copy all the files listed in Jimfile to the vendor_dir"
    def vendor(dir = nil)
      dir = bundler.vendor!(dir, force)
      say("Vendored files to #{dir}", :green)
    end

    desc "list [SEARCH]",
      "List all the installed packages and their versions, optionally limiting by [SEARCH]"
    def list(search = nil)
      say "Getting list of installed files in"
      say("#{installed_index.directories.join(':')}", :yellow)
      say("Searching for '#{search}'", :yellow) if search
      list = installed_index.list(search)
      say "Installed:"
      print_version_list(list)
    end
    map "installed" => "list"

    desc "available [SEARCH]",
      "List all available projects and versions " +
      "including those in the local path, or paths specified in a Jimfile"
    def available(search = nil)
      say "Getting list of all available files in\n#{index.directories.join("\n")}"
      say "Searching for '#{search}'" if search
      list = index.list(search)
      say "Available:"
      print_version_list(list)
    end

    desc "remove <NAME> [VERSION]",
      "Iterate through the install files and prompt for the removal of those " +
      "matching the supplied NAME and VERSION"
    def remove(name, version = nil)
      say "Looking for files matching #{name} #{version}"
      files = installed_index.find_all(name, version)
      if files.length > 0
        say "Found #{files.length} matching files"
        removed = 0
        files.each do |filename|
          do_remove = yes?("Remove #{filename}?", :red)
          if do_remove
            say "Removing #{filename}"
            filename.delete
            removed += 1
          else
            say "Skipping #{filename}", :yellow
          end
        end
        say "Removed #{removed} files."
      else
        say "No installed files matched."
      end
    end
    map "uninstall" => "remove"

    desc "resolve",
      "Resolve all the paths listed in a Jimfile and print them to STDOUT. " +
      "If no Jimfile is set in the options, assumes ./Jimfile."
    def resolve
      resolved = bundler.resolve!
      say "Files:"
      resolved.each do |r|
        say r.join(" | ")
      end
      resolved
    end

    desc "pack [DIR]",
      "Runs in order, vendor, bundle, compress. This command " +
      "simplifies the common workflow of vendoring and re-bundling " +
      "before committing or deploying changes to a project"
    def pack(dir = nil)
      say "Packing the Jimfile for this project"
      invoke :vendor, [dir]
      invoke :bundle
      invoke :compress
    end

    desc "watch [DIR]",
      "Watches your Jimfile and JS files and triggers `bundle` if something " +
      "changes. Handy for development."
    def watch(dir = nil)
      say "Now watching JS files..."
      FSSM.monitor(Dir.pwd, [File.join('**','*.js'), 'Jimfile']) do
        update do |base, relative|
          unless relative.include?('bundled.js')
            puts "--> #{relative} changed!"
            system "jim bundle"
          end
        end

        create do |base, relative|
          unless relative.include?('bundled.js')
            puts "--> #{relative} created!"
            system "jim bundle"
          end
        end

        delete do |base, relative|
          puts "--> #{relative} deleted!"
          system "jim bundle"
        end
      end
    end

    desc "update_jimfile [APP_DIR]",
      "Converts a Jimfile from the old > 0.3 format to the JSON format."
    def update_jimfile(dir = nil)
      dir = Pathname.new(dir || '')
      bundler
      copy_file(dir + 'Jimfile', dir + 'Jimfile.old')
      create_file(dir + 'Jimfile', bundler.jimfile_to_json)
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

    def logger
      Jim.logger
    end

    def print_version_list(list)
      list.each do |file, versions|
        say"#{file} (#{VersionSorter.rsort(versions.collect {|v| v[0] }).join(', ')})"
      end
    end

    def make_bundle(bundle_name, compress = false)
      bundler.bundle_dir = options[:bundle_dir] if options[:bundle_dir]
      bundler.bundle_dir = nil if options[:stdout]
      result = bundler.bundle!(bundle_name, compress)
      if options[:stdout]
        puts result
      else
        result.each do |path|
          say("Wrote #{path} #{File.size(path.to_s) / 1024}kb", :green)
        end
      end
    end

  end
end
