# Rack::SSI

Rack middleware for processing SSI based on the [nginx HttpSsiModule](http://wiki.nginx.org/HttpSsiModule).
Directives currently supported: `block` and `include`

## Installation

Add this line to your application's Gemfile:

    gem 'rack_ssi', :git => "git@github.com:forward/rack-ssi.git"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack_ssi

## Usage

    require 'rack_ssi'
    
### Sinatra

    configure do
      use Rack::SSI, {
        :logging => :on,
        :when => lambda {|env| not env['SOME_CUSTOM_HEADER'] == 'ON'},
        :locations => {
          %r{^/includes} => "http://includes.mydomain.com"
        }
      }
    end
    
### Rails

    config.middleware.use Rack::SSI, { ... }    

