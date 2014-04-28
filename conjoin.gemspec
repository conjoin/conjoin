# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjoin/version'

Gem::Specification.new do |spec|
  spec.name          = "conjoin"
  spec.version       = Conjoin::VERSION
  spec.authors       = ["cj"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.description   = %q{Adds certain things to Cuba to make it more familiar to rails devs}
  spec.summary       = %q{Adds certain things to Cuba to make it more familiar to rails devs}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "cuba", "~> 3.1.1"
  spec.add_dependency "cuba-sugar"
  spec.add_dependency "rack_csrf", "~> 2.4.0"
  spec.add_dependency "rack-protection", "~> 1.5.2"
  spec.add_dependency "r18n-core"
  spec.add_dependency 'highline', '~> 1.6.11'
  spec.add_dependency "mab"
  spec.add_dependency "tilt"
  spec.add_dependency "sass"
  spec.add_dependency "stylus"
  spec.add_dependency "coffee-script"
  spec.add_dependency "slim"
  spec.add_dependency "mimemagic"
  spec.add_dependency "rake"
  spec.add_dependency "hashie"
  spec.add_dependency "chronic"
  spec.add_dependency "unicorn"
  spec.add_dependency "clap"
  spec.add_dependency "shield"
  spec.add_dependency "better_errors"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
