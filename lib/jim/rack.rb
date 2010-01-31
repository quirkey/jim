require 'jim'

module Jim
  class Rack
   
    def initialize(app, options = {})
      @app = app
      jimfile = Pathname.new(options[:jimfile] || 'jimfile')
      jimhome = Pathname.new(options[:jimhome] || ENV['JIMHOME'] || '~/.jim').expand_path
      @bundler = Jim::Bundler.new(jimfile, jimhome, options)
    end
   
    def call(env)
      dup._call(env)
    end
   
    def _call(env)
      if env.request_uri == @bundler.options[:bundled_path]
        [200, {'Content-Type' => 'text/javascript'}, @bundler.bundle!(false)]
      else
        @app.call(env)
      end
    end
    
  end
end