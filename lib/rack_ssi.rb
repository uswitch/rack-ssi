require 'rest_client'

module Rack
  class SSI
    
    VERSION = "0.0.1"
    
    def initialize(app, options = {})
      @app = app
      @options = {:locations => {}}.merge(options)
    end

    def call(env)
      status, headers, body = @app.call(env)
      if status == 200 && headers["Content-Type"].include?("text/html")
        new_body = process(body)      
        headers["Content-Length"] = (new_body.reduce(0) {|sum, part| sum + part.bytesize}).to_s
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
        new_part = process_block(part) {|name, content| blocks[name] = content}
        process_include(new_part, blocks)
      end
    end
    
    def process_block(part)
      part.gsub(/<!--# block\s+name="(\w+)"\s+-->(.*?)<!--#\s+endblock\s+-->/) do
        yield [$1,$2]
        ""
      end
    end
    
    def process_include(part, blocks)
      part.gsub(/<!--#\s+include\s+(?:virtual|file)="([^"]+)"(?:\s+stub="(\w+)")?\s+-->/) do
        location, stub = $1, $2
        status, _, body = fetch location
        if stub && (status != 200 || body.nil? || body == "")
          blocks[stub] 
        else
          body
        end
      end
    end
    
    def fetch(location)
      @options[:locations].select{|k,v| k.is_a?(String)}.each do |pattern, host|
        return _get("#{host}#{location}") if location == pattern
      end
      @options[:locations].select{|k,v| k.is_a?(Regexp)}.each do |pattern, host|
        return _get("#{host}#{location}") if location =~ pattern
      end
    end
    
    private
    
    def _get(url)
      RestClient.get(url){|response, request, result| [response.code, response.headers, response.body]}
    end

  end
end
