# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Thibaut Sacreste"]
  gem.email         = ["thibaut.sacreste@gmail.com"]
  gem.description   = <<-EOS
    Rack middleware for processing SSI based on the nginx HttpSsiModule.
    Directives currently supported: 'block' and 'include'
  EOS
  gem.summary       = "Rack middleware for processing SSI based on the nginx HttpSsiModule."
  gem.homepage      = "https://github.com/uswitch/rack-ssi"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack_ssi"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.9"
  gem.add_dependency "httparty"

  gem.add_development_dependency "rake", '~> 10.4.2'
  gem.add_development_dependency "rspec", '~> 3.2'
end
