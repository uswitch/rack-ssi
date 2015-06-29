require 'compatibility'
require 'ssi_processor'
require 'httparty'
require 'logger'

module Rack
  class SSI

    attr_accessor :app, :logging, :predicate, :processor_options

    def initialize(app, options = {})
      @app = app
      @logging = options[:logging]
      @predicate = options[:when] || ->(*) { true}
      @processor_options = {}
      processor_options[:locations] = options.fetch(:locations, {})
      processor_options[:headers] = options.fetch :headers, ->(env) do
        env['HTTP_COOKIE'] ? {'Cookie' => env['HTTP_COOKIE']} : {}
      end
    end

    def call(env)
      status, headers, body = app.call(env)
      unprocessed = [status, headers, body]

      return unprocessed unless predicate.call(env)
      return unprocessed unless headers["Content-Type"] && headers["Content-Type"].include?("text/html")

      ssi = Rack::SSIProcessor.new(env, logging && logger(env), processor_options)
      new_body = ssi.process(body)
      headers["Content-Length"] = (new_body.reduce(0) {|sum, part| sum + part.bytesize}).to_s

      [status, headers, new_body]
    end


    private

    def logger(env)
      if defined?(Rails) && defined?(Rails.logger)
        Rails.logger
      else
        env['rack.logger']
      end
    end
  end
end
