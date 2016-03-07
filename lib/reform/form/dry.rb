require "dry-validation"
require "dry/validation/schema/form"
require "reform/validation"

module Reform::Form::Dry
  module Validations

    def build_errors
      Reform::Contract::Errors.new(self)
    end

    module ClassMethods
      def validation_group_class
        Group
      end
    end

    def self.included(includer)
      includer.extend(ClassMethods)
    end

    class Group
      def initialize
        @validator = Class.new(ValidatorSchema)
      end

      def instance_exec(&block)
        @validator.class_eval(&block)
      end

      def call(fields, reform_errors, form)
        validator = @validator.new(form)
        # a message item looks like: {:confirm_password=>["confirm_password size cannot be less than 2"]}
        validator.call(fields).messages.each do |field, dry_error|
          dry_error.each do |attr_error|
            reform_errors.add(field, attr_error)
          end
        end
      end
    end

    class ValidatorSchema < Dry::Validation::Schema::Form
      def initialize(form)
        @form = form
        super()
      end

      def form
        @form
      end
    end
  end
end
