require 'jim'

module Jim
  # Jim::Rack is a Rack middleware for allowing live bundling and compression
  # of the requirements in your Jimfile without having to rebundle using the command
  # line. You can specify a number of options:
  #
  # :jimfile: Path to your Jimfile (default ./Jimfile)
  # :jimhome: Path to your JIMHOME directory (default ENV['JIMHOME'] or ~/.jim)
  # :bundled_uri: URI to serve the bundled requirements
  # :compressed_uri: URI to serve the compressed requirements
  class Rack
   
    def initialize(app, options = {})
      @app = app
      jimfile = Pathname.new(options[:jimfile] || 'Jimfile')
      jimhome = Pathname.new(options[:jimhome] || ENV['JIMHOME'] || '~/.jim').expand_path
      @bundler = Jim::Bundler.new(jimfile, Jim::Index.new(jimhome), options)
      @bundled_uri    = options[:bundled_uri] || @bundler.options[:bundled_path]
      @compressed_uri = options[:compressed_uri] || @bundler.options[:compressed_path]
    end
   
    def call(env)
      dup._call(env)
    end
   
    def _call(env)
      uri = env['PATH_INFO']
      if uri == @bundled_uri
        run_action(:bundle!)
      elsif uri == @compressed_uri
        run_action(:compress!)
      else
        @app.call(env)
      end
    end
    
    def run_action(which)
      # wrap body in an array for compatibility with Rack and 1.9
      # because the Rack response must respond to each, but String no longer
      # does in 1.9
      begin
        [200, {'Content-Type' => 'text/javascript'}, [@bundler.send(which, false)]]
      rescue => e
        response = <<-EOT 
          <p>Jim failed in helping you out. There was an error when trying to #{which}.</p>
          <p>#{e}</p>
          <pre>#{e.backtrace}</pre>
        EOT
        [500, {'Content-Type' => 'text/html'}, [response]]
      end
    end
    
  end
end