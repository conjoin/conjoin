# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjoin/version'

Gem::Specification.new do |spec|
  spec.name          = "conjoin"
  spec.version       = Conjoin::VERSION
  spec.authors       = ["cj"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.description   = %q{Still in development}
  spec.summary       = %q{Adds certain things to Cuba to make it more familiar to rails devs}
  spec.homepage      = "http://conjoin.me"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "cuba", "~> 3.1.1", '>= 3.1.1'
  spec.add_dependency "cuba-sugar", "~> 0.3.0", '>= 0.3.0'
  spec.add_dependency "rack_csrf", "~> 2.4.0", '>= 2.4.0'
  spec.add_dependency "rack-protection", "~> 1.5.2", '>= 1.5.2'
  spec.add_dependency "r18n-core", "~> 1.1.10", '>= 1.1.10'
  spec.add_dependency 'highline', '~> 1.6.11', '>= 1.6.11'
  spec.add_dependency "mab", '~> 0.0.3', '>= 0.0.3'
  spec.add_dependency "tilt", '~> 2.0.1', '>= 2.0.1'
  spec.add_dependency "sass", '~> 3.3.6', '>= 3.3.6'
  spec.add_dependency "stylus", '~> 1.0.1', '>= 1.0.1'
  spec.add_dependency "coffee-script", '~> 2.2.0', '>= 2.2.0'
  spec.add_dependency "slim", '~> 2.0.2', '>= 2.0.2'
  spec.add_dependency "mimemagic", '~> 0.2.1', '>= 0.2.1'
  spec.add_dependency "rake", '~> 10.3.1', '>= 10.3.1'
  spec.add_dependency "hashie", '~> 2.1.1', '>= 2.1.1'
  spec.add_dependency "chronic", '~> 0.10.2', '>= 0.10.2'
  spec.add_dependency "unicorn", '~> 4.8.2', '>= 4.8.2'
  spec.add_dependency "clap", '~> 1.0.0', '>= 1.0.0'
  spec.add_dependency "shield", '~> 2.1.0', '>= 2.1.0'
  spec.add_dependency "better_errors", '~> 1.1.0', '>= 1.1.0'

  spec.add_development_dependency "bundler", "~> 1.3", '>= 1.3'
  spec.add_development_dependency "rake", '~> 10.3.1', '>= 10.3.1'
end
