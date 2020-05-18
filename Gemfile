source "https://rubygems.org"

gemspec

# gem "disposable", path: "../disposable"

# just trying to add `dry-monads` correct version in base on dry-validation
dry_v_version = ENV.fetch('DRY_VALIDATION', '~> 0.13.0').gsub("~>", "").to_f
gem 'dry-monads', "~> #{[dry_v_version, 1.3].min}" if dry_v_version >= 1
gem 'dry-validation', ENV.fetch('DRY_VALIDATION', '~> 0.13.0')
