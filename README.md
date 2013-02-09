# Rack::SSI

Rack middleware for processing SSI based on the [nginx HttpSsiModule](http://wiki.nginx.org/HttpSsiModule).
Directives currently supported: `block` and `include`

## Installation

Add this line to your application's Gemfile:

    gem 'rack_ssi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack_ssi

## Usage

    require 'rack_ssi'
    
### Sinatra
```ruby
configure do
  use Rack::SSI, {
    :logging => :on,
    :when => lambda {|env| not env['SOME_CUSTOM_HEADER'] == 'ON'},
    :locations => {
      %r{^/includes} => "http://includes.mydomain.com"
    }
  }
end
```    
### Rails
```ruby
config.middleware.use Rack::SSI, { ... }    
```

#### Haml

To use includes in your HAML, the following should work ok:

```ruby
!!!
%html{:xmlns => "http://www.w3.org/1999/xhtml"}
  %head
    %title My site
      / #include file="tools/includes/header.html"
```
