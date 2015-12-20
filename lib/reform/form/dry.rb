require "dry-validation"
require "reform/validation"
require "dry/validation/schema/form"

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

        validator.call(fields).messages.each do |dry_error|
          # a dry error message looks like this:
          # [:email, [['Please provide your email', '']]]
          dry_error[1].each do |attr_error|
            reform_errors.add(dry_error[0], attr_error[0])
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
