module Jim
  class CLI
    
    attr_accessor :jimfile
    
    def intitialize(args)
      
    end
    
    def init
      
    end
    
    def install
      
    end
    
    def bundle
      
    end
    
    def vendor
      
    end
    
    private
    def parse_options(runtime_args)
      OptionParser.new("", 24, '  ') do |opts|
        opts.banner = "Usage: jim [options] [args]"

        opts.separator ""
        opts.separator "jim options:"

        opts.on("-j", "--jimfile path/to/jimfile", "load specific jimfile at path (default ./jimfile)") { |j|
          self.jimfile = Pathname.new(j)
        }
        opts.on_tail("-h", "--help", "Show this message") do
          @output << opts.to_s
          exit
        end

      end.parse! runtime_args
    rescue OptionParser::MissingArgument => e
      logger.warn "#{e}, run -h for options"
      exit
    end
    
  end
end