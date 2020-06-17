gem "dry-validation", "~> 1.0"
require "dry-validation"
require "reform/validation"
require "reform/form/dry/input_hash"
require "reform/form/dry/api"


module Reform::Form::Dry
  def self.included(includer)
    includer.send :include, Reform::Form::Dry::Api::Validations
  end
end
