# jim

jim is your friendly javascript library manager. 
He downloads, stores, bundles, vendors and compresses.

## What is a jim?

I'm frustrated with a lot of copy and pasting JS files from one directory to
another and downloading new versions to who knows where and only really being 
able to use sprockets in Rails and lots of other small annoying things about 
the existing JS package/asset managers. 

Jim uses a lot of stolen ideas from a lot of great projects. Namely:

* version management and flexible project fetching from rip
* asset compression from jammit and sprockets
* Gemfile and bundle from bundler

The goals are simple:

* Install a file, archive, git repo, etc from a local path or a URL into a 
  common directory stored with a specific name and version number. Because 
  should be able to install anything from anywhere, theres no need for a  
  central package host.
* Specify the local and installed files required for a project by name and 
  version number in a single place. Dependencies for each project are not   
  managed by the system, the onus is on you to specify them in the order you  
  want them. _The project does not have to be in Ruby or even have a backend  
  system._
* Run a command to bundle all the required files into a single file.
* Run a command to bundle the files _and_ run them through a JavaScript   
  compressor.

So far I've accomplished the goals, but this is all very very very beta and   
the API is sure to change and thing straight-up might not work.

## Install

jim is a rubygem:

    $ gem install jim

You can also clone the source from github and use jeweler to install locally (requires jeweler):

    $ git clone git://github.com/quirkey/jim.git
    $ cd jim
    $ rake install

## Usage

From anywhere, install a project:

    // From a URL
    $ jim install http://code.jquery.com/jquery-1.4.2.js
    // From a zip (with name and version)
    $ jim install http://github.com/jquery/jquery-metadata/zipball/master jquery-metadata 2.0

In your project run:

    $ jim init

Which creates an empty `Jimfile`. Open it up and add your requirements:

    {
      "bundle_dir": "public/javascripts/",
      "vendor_dir": "public/javascripts/vendor",
      "bundles": {
        "default": [
          ["jquery", "1.4.1"],
          "sammy",
          "app"
        ],
        "mobile": [
          "jquery",
          "mobile"
        ]
      }
    }
  
As of v0.3 you can specified multiple named bundles. Each requirement is 
specified in order of inclusion and can be either simply the name of the 
library (`"jquery"`) or an array of name and version (`["jquery", "1.4.2"]`).

If its a rack-based project, mount the Jim::Rack middleware. It gives you live 
updates of your bundled and compressed js files:

    use Jim::Rack, :bundle_uri => '/js/'
    
    # GET /js/default.js # get by bundle name
    # GET /js/mobile.js
    # GET /js/mobile.min.js # compressed

Otherwise and also before deploys, etc, use the command line tool from your project's dir:

    # Bundle into your bundle_dir
    $ jim bundle 
    
    # Compress into your bundle dir
    $ jim compress

    # Copy all the requirements from your JIMHOME into vendor dir 
    # (before you commit)
    $ jim vendor
    
    # What you run before deploys. Runs vendor -> bundle -> compress.
    $ jim pack

In order for `compress` to work, you need either the yui-compressor gem or the 
closure-compiler gem. Closure is the default.

Run `jim help` for a full list of commands and `jim help [COMMAND]` for help 
with a specific command.

## You're probably wondering

### Why not implement it in JavaScript itself?

CommonJS has certainly come a long way in a year, but in general the file 
system support and variety of libraries just isn't completely there yet for 
this type of project (IMHO). Also, I love Ruby and writing this was actually 
fun and pretty fast. 

With that said, I would gladly welcome anyone cloning the API in CommonJS (I'm 
just being lazy about it)

### Does it work with __ library or __ development platform?

Probably?? Its all very new at this point so please test it out and let me 
know.

## Contributors

Jim is mostly written by Aaron Quint, but not without the help of 
[these fine individuals.](https://github.com/quirkey/jim/contributors)

Also, Thanks to Yehuda Katz for talking through some of the original ideas.

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a 
  commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches

## Copyright

Copyright (c) 2010 Aaron Quint. See LICENSE for details.
