# Rack::SSI

Rack middleware for processing SSI based on the [nginx HttpSsiModule](http://wiki.nginx.org/HttpSsiModule).
Directives currently supported: 'block' and 'include'

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

    configure :development do
      use Rack::SSI, {
        :logging => :on,
        :locations => {
          %r{^/includes} => "http://includes.mydomain.com"
        }
      }
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
