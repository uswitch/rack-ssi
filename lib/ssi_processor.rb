module Rack
  class SSIProcessor
    
    attr_accessor :logger, :locations
    
    def process(body)
      # see http://wiki.nginx.org/HttpSsiModule
      # currently only supporting 'block' and 'include' directives
      blocks = {}
      output = []
      body.each do |part|
        new_part = process_block(part) {|name, content| blocks[name] = content}
        output << process_include(new_part, blocks)
      end
      output
    end
    
    def process_block(part)
      part.gsub(/<!--# block\s+name="(\w+)"\s+-->(.*?)<!--#\s+endblock\s+-->/) do
        name, content = $1, $2
        _info "processing block directive with name=#{name}"
        yield [name, content]
        ""
      end
    end
    
    def process_include(part, blocks)
      part.gsub(/<!--#\s+include\s+(?:virtual|file)="([^"]+)"(?:\s+stub="(\w+)")?\s+-->/) do
        location, stub = $1, $2
        _info "processing include directive with location=#{location}"
        status, _, body = fetch location
        if stub && (status != 200 || body.nil? || body == "")
          blocks[stub] 
        else
          body
        end
      end
    end
    
    def fetch(location)
      locations.select{|k,v| k.is_a?(String)}.each do |pattern, host|
        return _get("#{host}#{location}") if location == pattern
      end
      locations.select{|k,v| k.is_a?(Regexp)}.each do |pattern, host|
        return _get("#{host}#{location}") if location =~ pattern
      end
      _error "no match found for location=#{location}"
    end
    
    private
    
    def _get(url)
      _info "fetching #{url}"
      RestClient.get(url) do |response, request, result|
        _error "error fetching #{url}: #{response.code} response" if response.code != 200
        [response.code, response.headers, response.body]
      end
    end
    
    def _info(message)
      logger.info "Rack::SSI #{message}" if logger
    end

    def _error(message)
      logger.info "Rack::SSI #{message}" if logger
    end
    
  end
end