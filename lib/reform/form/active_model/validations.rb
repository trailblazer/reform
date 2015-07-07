require "active_model"
require "reform/contract/errors"

module Reform::Form::ActiveModel
  # AM::Validations for your form.
  #
  # Note: The preferred way for validations should be Lotus::Validations, as ActiveModel::Validation's implementation is
  # old, very complex given that it needs to do a simple thing, and it's using globals like @errors.
  module Validations
    def self.included(includer)
      includer.send(:include, Reform::Contract::Validate)

      includer.instance_eval do
        extend Uber::InheritableAttr
        inheritable_attr :validator
        self.validator = Class.new(Validator)

        class << self
          extend Uber::Delegates
          delegates :validator, :validates, :validate, :validates_with, :validate_with
        end
      end
    end

    # Builder.
    def errors_for_validate
      Reform::Contract::Errors.new(self)
    end


    class Validator < SimpleDelegator
      include ActiveModel::Validations

      def self.name
        "ba"
      end

      def self.clone
        Class.new(self)
      end
    end

    def valid?
      validator = self.class.validator.new(self)
      validator.valid? # run the Validations object's validator with the form as context. this won't pollute anything in the form.

      form_errors = errors.messages # errors that might have been added manually via errors.add.
      @errors = validator.errors
      form_errors.each { |k, v| @errors.add(k, *v) }

      @errors.empty?
    end
  end
end