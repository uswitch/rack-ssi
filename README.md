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
        :when => lambda {|env| not env['HTTP_X_USWITCH_SSI'] == 'ON'},
        :locations => {
          %r{^/includes} => "http://uswitch-includes.uswitchinternal.com"
        }
      }
    end
    
### Rails

    config.middleware.use Rack::SSI, { ... }    

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
