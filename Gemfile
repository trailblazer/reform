source "https://rubygems.org"

gemspec

# gem "disposable", path: "../disposable"

# just trying to add `dry-monads` correct version in base on dry-validation
dry_v_version = ENV.fetch('DRY_VALIDATION', '~> 0.13.0')
dry_m_version = "~> #{dry_v_version.gsub("~>", "").to_f}.0"
gem 'dry-monads', dry_m_version if dry_v_version.gsub("~>", "").to_f >= 1
gem 'dry-validation', ENV.fetch('DRY_VALIDATION', '~> 0.13.0')
