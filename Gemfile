source "https://rubygems.org"

gemspec

# gem "disposable", path: "../disposable"

{ "dry-types" => (ENV['DRY_TYPES'] || '~> 0.14.0'), "dry-validation" => ENV['DRY_VALIDATION'] || '~> 0.13.0'}.each do |gem_name, dependency|
  gem gem_name, dependency
end
