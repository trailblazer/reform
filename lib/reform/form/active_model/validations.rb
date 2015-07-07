require "active_model"
require "reform/contract/errors"

module Reform::Form::ActiveModel
  # AM::Validations for your form.
  module Validations
    def self.included(includer)
      # includer.send(:include, ::ActiveModel::Validations)
      includer.send(:include, Reform::Contract::Validate)

      includer.extend ClassMethods

      includer.instance_eval do
        extend Uber::InheritableAttr
        inheritable_attr :validations
        self.validations = Class.new(Validations)
      end
    end

    # Builder.
    def errors_for_validate
      Reform::Contract::Errors.new(self)
    end

    module ClassMethods
      def validates(*args)
        validations.validates(*args)
      end
      def validate(*args)
        validations.validate(*args)
      end
      def validate_with(*args)
        validations.validate_with(*args)
      end
      def validates_with(*args)
        validations.validates_with(*args)
      end
    end


    class Validations < SimpleDelegator
      include ActiveModel::Validations

      def self.name
        "ba"
      end

      def self.clone
        Class.new(self)
      end
    end

    def valid?
      validations = self.class.validations.new(self)
      validations.valid? # run the Validations object's validations with the form as context. this won't pollute anything in the form.

      form_errors = errors.messages # errors that might have been added manually via errors.add.
      @errors = validations.errors
      form_errors.each { |k, v| @errors.add(k, *v) }

      @errors.empty?
    end
  end
end