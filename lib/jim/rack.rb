require 'jim'

module Jim
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
      begin
        [200, {'Content-Type' => 'text/javascript'}, @bundler.send(which, false)]
      rescue => e
        [500, {'Content-Type' => 'text/html'}, <<-EOT 
          <p>Jim failed in helping you out. There was an error when trying to #{which}.</p>
          <p>#{e}</p>
          <pre>#{e.backtrace}</pre>
        EOT
        ]
      end
    end
    
  end
end