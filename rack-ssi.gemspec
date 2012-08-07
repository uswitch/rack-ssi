# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack_ssi', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Thibaut Sacreste"]
  gem.email         = ["thibaut.sacreste@gmail.com"]
  gem.description   = <<-EOS
    Rack middleware for processing SSI based on nginx HttpSsiModule.
    Directives currently supported: 'block' and 'include'
  EOS
  gem.summary       = "Rack middleware for processing SSI based on nginx HttpSsiModule."
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack-ssi"
  gem.require_paths = ["lib"]
  gem.version       = Rack::SSI::VERSION
  gem.add_dependency "rest-client"
end
