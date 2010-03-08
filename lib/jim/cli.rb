require 'optparse'
require 'readline'

module Jim
  
  # CLI handles the command line interface for the `jim` binary. 
  # The layout is farily simple. Options are parsed using optparse.rb and 
  # the different public methods represent 1-1 the commands provided by the bin.
  class CLI
    
    attr_accessor :jimfile, :jimhome, :force
    
    # create a new instance with the args passed from the command line i.e. ARGV
    def initialize(args)
      @output = ""
      # set the default jimhome
      self.jimhome = Pathname.new(ENV['JIMHOME'] || '~/.jim').expand_path
      # parse the options
      self.jimfile = Pathname.new('Jimfile')
      @args = parse_options(args)
      ## try to run based on args
    end
    
    # method called by the bin directly after initialization. 
    def run
      command = @args.shift
      if command && respond_to?(command)
        self.send(command, *@args)
      elsif command.nil? || command.strip == ''
        cheat
      else 
        @output << "No action found for #{command}. Run -h for help."
      end
      @output
    rescue ArgumentError => e
      @output << "#{e.message} for #{command}"
    rescue Jim::FileExists => e
      @output << "#{e.message} already exists, bailing. Use --force if you're sure"
    rescue => e
      @output << e.message + " (#{e.class})"
    end
    
    # list the possible commands to the logger
    def commands
      logger.info "Usage: jim [options] [command] [args]\n"
      logger.info "Commands:"
      logger.info template('commands')
    end
    
    # list the possible commands without detailed descriptions
    def cheat
      logger.info "Usage: jim [options] [command] [args]\n"
      logger.info "Commands:"
      logger.info [*template('commands')].grep(/^\w/).join
      logger.info "run commands for details"
    end
    
    # initialize the current dir with a new Jimfile
    def init(dir = nil)
      dir = Pathname.new(dir || '')
      jimfile_path = dir + 'Jimfile'
      if jimfile_path.readable? && !force
        raise Jim::FileExists(jimfile_path)
      else
        File.open(jimfile_path, 'w') do |f|
          f << template('Jimfile')
        end
        logger.info "wrote Jimfile to #{jimfile_path}"
      end
    end
    
    # install the file/project `url` into `jimhome`
    def install(url, name = false, version = false)
      Jim::Installer.new(url, jimhome, :force => force, :name => name, :version => version).install
    end
    
    # bundle the files specified in Jimfile into `to`
    def bundle(to = nil)
      path = bundler.bundle!(to)
    end
    
    # compress the files specified in Jimfile into `to`
    def compress(to = nil)
      path = bundler.compress!(to)
    end
    
    # copy/vendor all the files specified in Jimfile to `dir`
    def vendor(dir = nil)
      bundler.vendor!(dir)
    end
    
    # list the installed projects and versions
    def list
      logger.info "Getting list of installed files in #{index.directories.join(':')}"
      list = index.list
      logger.info "Installed:\n#{list.collect {|i| "#{i[0]} (#{i[1].join(', ')})"}.join("\n")}"
    end
    
    # Iterates over matching files and prompts for removal
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
    
    # list the files and their resolved paths specified in the Jimfile
    def resolve
      resolved = bundler.resolve!
      logger.info "Files:\n#{resolved.join("\n")}"
      resolved
    end
        
    private
    def parse_options(runtime_args)
      OptionParser.new("", 24, '  ') do |opts|
        opts.banner = "Usage: jim [options] [command] [args]"

        opts.separator ""
        opts.separator "jim options:"
        
        opts.on("--jimhome path/to/home", "set the install path/JIMHOME dir (default ~/.jim)") {|h| 
          self.jimhome = Pathname.new(h)
        }

        opts.on("-j", "--jimfile path/to/jimfile", "load specific Jimfile at path (default ./Jimfile)") { |j|
          self.jimfile = Pathname.new(j)
        }
        
        opts.on("-f", "--force", "force file creation/overwrite") {|f|
          self.force = true
        }
        
        opts.on("-d", "--debug", "set log level to debug") {|d|
          logger.level = Logger::DEBUG
        }
        
        opts.on("-v", "--version", "print version") {|d|
          puts "jim #{Jim::VERSION}"
          exit
        }
        
        opts.on_tail("-h", "--help", "Show this message. Run jim commands for list of commands.") do
          puts opts.help
          exit
        end

      end.parse! runtime_args
    rescue OptionParser::MissingArgument => e
      logger.warn "#{e}, run -h for options"
      exit
    end
    
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
    
  end
end