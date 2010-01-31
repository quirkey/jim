module Jim
  class CLI
    
    attr_accessor :jimfile, :jimhome
    
    def initialize(args)
      @output = ""
      # set the default jimhome
      self.jimhome = Pathname.new(ENV['JIMHOME'] || '~/.jim').expand_path
      # parse the options
      self.jimfile = Pathname.new('jimfile')
      @args = parse_options(args)
      ## try to run based on args
    end
    
    def run
      command = @args.shift
      if command && respond_to?(command)
        self.send(command, *@args)
      else 
        @output << "No action found for #{command}. Run -h for help."
      end
      @output
    rescue => e
      @output << e.message + " (#{e.class})"
    end
    
    def init(dir = nil)
      dir = Pathname.new(dir || '')
      jimfile_path = dir + 'jimfile'
      if jimfile_path.readable?
        logger.warn "jimfile already exists at #{jimfile_path}"
      else
        File.open(jimfile_path, 'w') do |f|
          f << template('jimfile')
        end
        logger.info "wrote jimfile to #{jimfile_path}"
      end
    end
    
    def install(url)
      Jim::Installer.new(url, jimhome).install
    end
    
    def bundle(to = nil)
      path = bundler.bundle!(to)
    end
    
    def compress(to = nil)
      path = bundler.compress!(to)
    end
    
    def resolve
      resolved = bundler.resolve!
      logger.info "Files:\n#{resolved.join("\n")}"
      resolved
    end
    
    def vendor(dir = nil)
      bundler.vendor!(dir)
    end
    
    private
    def parse_options(runtime_args)
      OptionParser.new("", 24, '  ') do |opts|
        opts.banner = "Usage: jim [options] [args]"

        opts.separator ""
        opts.separator "jim options:"
        
        opts.on("--jimhome path/to/home", "set the install path/JIMHOME dir (default ~/.jim)") {|h| 
          self.jimhome = Pathname.new(h)
        }

        opts.on("-j", "--jimfile path/to/jimfile", "load specific jimfile at path (default ./jimfile)") { |j|
          self.jimfile = Pathname.new(j)
        }
        
        opts.on("-d", "--debug", "set log level to debug") {|d|
          logger.level = Logger::DEBUG
        }
        
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts.to_s
          exit
        end

      end.parse! runtime_args
    rescue OptionParser::MissingArgument => e
      logger.warn "#{e}, run -h for options"
      exit
    end
    
    def index
      @index ||= Jim::Index.new(jimhome + 'lib')
    end
    
    def bundler
      @bundler ||= Jim::Bundler.new(jimfile, index)
    end
    
    def template(path)
      (Pathname.new(__FILE__).dirname + 'templates' + path).read
    end
    
    def logger
      Jim.logger
    end
    
  end
end