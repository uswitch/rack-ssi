require File.expand_path('../ssi_processor', __FILE__)
require 'rest_client'
require 'logger'

module Rack
  class SSI
    
    VERSION = "0.0.1"
    
    def initialize(app, options = {})
      @app = app
      @logging = options[:logging] == :on
      @locations = options[:locations] || {}
    end

    def call(env)
      status, headers, body = @app.call(env)
      if status == 200 && headers["Content-Type"].include?("text/html")
        ssi = Rack::SSIProcessor.new
        ssi.locations = @locations
        ssi.logger = env['rack.logger'] if @logging        
        new_body = ssi.process(body)      
        headers["Content-Length"] = (new_body.reduce(0) {|sum, part| sum + part.bytesize}).to_s
      else
        new_body = body
      end      
      [status, headers, new_body]
    end

  end
end
