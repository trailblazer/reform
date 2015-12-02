require "dry-validation"
require "reform/validation"

require 'byebug'

# Implements ::validates and friends, and #valid?.
module Reform::Form::Dry
  module Validations

    def build_errors
      Reform::Contract::Errors.new
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

        validator.(Dry::Validation.symbolize_keys(fields)).each do |dry_error|
          pp lookup_message(validator.class, dry_error)
          reform_errors.add(dry_error.result.rule.name,
                            lookup_message(validator.class, dry_error))
                            # {
                            #   validation: dry_error.result.rule.predicate.id,
                            #   invalid_input: dry_error.result.input,
                            #   message: lookup_message(validator.class, dry_error)
                            # })
        end
      end

      private

      def lookup_message(validator_class, dry_error)
        validator_class.messages.lookup(dry_error.result.rule.predicate.id,
                                        dry_error.result.rule.name,
                                        dry_error.result.rule.predicate.args)
      end
    end

    class ValidatorSchema < Dry::Validation::Schema
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
