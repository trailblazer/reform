require "dry-validation"
require "dry/validation/version"
require "reform/validation"
require "reform/form/dry/input_hash"

module Reform::Form::Dry
  def self.included(includer)
    if Gem::Version.new(Dry::Validation::VERSION) > Gem::Version.new("0.13.3")
      require "reform/form/dry/new_api"
      validations = Reform::Form::Dry::NewApi::Validations
    else
      require "reform/form/dry/old_api"
      validations = Reform::Form::Dry::OldApi::Validations
    end

    includer.send :include, validations
    includer.extend validations::ClassMethods
  end
end
