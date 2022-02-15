lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "reform/version"

Gem::Specification.new do |spec|
  spec.name          = "reform"
  spec.version       = Reform::VERSION
  spec.authors       = ["Nick Sutterer", "Fran Worley"]
  spec.email         = ["apotonick@gmail.com", "frances@safetytoolbox.co.uk"]
  spec.description   = "Form object decoupled from models."
  spec.summary       = "Form object decoupled from models with validation, population and presentation."
  spec.homepage      = "https://github.com/trailblazer/reform"
  spec.license       = "LGPL-3.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r(^bin/)) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # spec.add_dependency             "disposable",     ">= 0.6.0", "< 1.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-fest"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "multi_json"
  spec.add_development_dependency "rake"
end
