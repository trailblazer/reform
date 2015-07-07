require "active_model"
require "reform/contract/errors"

module Reform::Form::ActiveModel
  # AM::Validations for your form.
  module Validations
    def self.included(includer)
      includer.send(:include, ::ActiveModel::Validations)
      includer.send(:include, Reform::Contract::Validate)
    end

    # Builder.
    def errors_for_validate
      Reform::Contract::Errors.new(self)
    end


  end
end