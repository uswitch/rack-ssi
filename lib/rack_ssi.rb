require "rack_ssi/version"

module Rack
  class SSI
    
    VERSION = "0.0.1"
    
    def initialize(app, options = {})
      @app = app
      @options = {:locations => {}}.merge(options)
    end

    def call(env)
      status, headers, body = @app.call(env)
      if status == 200 && @headers["Content-Type"].include?("text/html")
        new_body = process(body)      
        @headers["Content-Length"] = new_body.reduce(0) {|sum, part| sum + part.bytesize}
      else
        new_body = body
      end      
      [status, headers, new_body]
    end
    
    def process(body)
      # see http://wiki.nginx.org/HttpSsiModule
      # currently only supporting 'block' and 'include' directives
      
      blocks = {}
      body.map do |part|
        
        # <!--# block name="joe_the_block" -->Oh dear!<!--# endblock -->
        part.gsub!(/<!--# block\s+name="(\w+)"\s+-->(.*?)<!--#\s+endblock\s+-->/) do
          blocks[$1] = $2
          ""
        end
        
        # <!--# include virtual="/boiler-cover/application/status" stub="shush" -->
        part.gsub!(/<!--#\s+include\s+(?:virtual|file)="([^"]+)"(?:\s+stub="(\w+)")?\s+-->/) do
          ssi_include($1) || ($2 && blocks[$2]) || "Error fetching $1 SSI include"
        end
        
        part
      end
    end
    
    def ssi_include(location)
      @options[:locations].select{|k,v| k.is_a?(String)}.each do |pattern, host|
        return fetch("#{host}#{location}") if pattern == location
      end
      @options[:locations].select{|k,v| k.is_a?(Regex)}.each do |pattern, host|
        return fetch("#{host}#{location}") if location =~ pattern
      end
    end

  end
end
