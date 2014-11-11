# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reform/version'

Gem::Specification.new do |spec|
  spec.name          = "reform"
  spec.version       = Reform::VERSION
  spec.authors       = ["Nick Sutterer", "Garrett Heinlen"]
  spec.email         = ["apotonick@gmail.com", "heinleng@gmail.com"]
  spec.description   = %q{Freeing your AR models from form logic.}
  spec.summary       = %q{Decouples your models from form by giving you form objects with validation, presentation, workflows and security.}
  spec.homepage      = "https://github.com/apotonick/reform"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency             "representable",  "~> 2.1.0"
  spec.add_dependency             "disposable",     "~> 0.0.5"
  spec.add_dependency             "uber",           "~> 0.0.11"
  spec.add_dependency             "activemodel"
  spec.add_development_dependency "bundler",        "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest",       "5.4.1"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "virtus"
  spec.add_development_dependency "rails"

  spec.add_development_dependency "actionpack"
end
