module Rack
  class SSIProcessor

    attr_accessor :logger, :locations, :env, :options

    def initialize(env, logger = nil, options = {})
      @env = env
      @logger = logger
      @options = options
    end

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
      part.gsub(/<!--\s?#\s?block\s+name="(\w+)"\s+-->(.*?)<!--\s?#\s+endblock\s+-->/) do
        name, content = $1, $2
        _info "processing block directive with name=#{name}"
        yield [name, content]
        ""
      end
    end

    def process_include(part, blocks)
      part.gsub(/<!--\s?#\s?include\s+(?:virtual|file)="([^"]+)"(?:\s+stub="(\w+)")?\s+-->/) do
        location, stub = $1, $2
        _info "processing include directive with location=#{location}"
        status, _, body = fetch location
        if stub && (status != 200 || body.nil? || body == "")
          blocks[stub]
        else
          body.force_encoding(part.encoding)
        end
      end
    end

    def fetch(location)
      options[:locations].each do |pattern, host|
        next unless pattern === location
        target = if host.is_a?(Proc)
          host.call(location)
        else
          "#{host}#{location}"
        end
        return _get(target)
      end
      _error "no match found for location=#{location}"
    end

    private

    def _get(url)
      _info "fetching #{url}"
      headers = options[:headers].call(env)
      response = HTTParty.get(url, headers: headers, verify: false)
      _error "error fetching #{url}: #{response.code} response" if response.code != 200
      [response.code, response.headers, response.body]
    end

    def _info(message)
      logger.info "Rack::SSI #{message}" if logger
    end

    def _error(message)
      logger.info "Rack::SSI #{message}" if logger
    end

  end
end
