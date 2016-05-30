require "dry-validation"
require "dry/validation/schema/form"
require "reform/validation"

module Reform::Form::Dry
  def self.included(includer)
    includer.send :include, Validations
    includer.extend Validations::ClassMethods
  end

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
        @schemas = []
      end

      def instance_exec(&block)
        @schemas << block
        @validator = Builder.new(@schemas.dup).validation_graph
      end

      def call(fields, reform_errors, form)
        # a message item looks like: {:confirm_password=>["confirm_password size cannot be less than 2"]}
        @validator.with(form: form).call(fields).messages.each do |field, dry_error|
          dry_error.each do |attr_error|
            reform_errors.add(field, attr_error)
          end
        end
      end

      class Builder < Array
        def initialize(array)
          super(array)
          @validator = Dry::Validation.Form({}, &shift)
        end

        def validation_graph
          build_graph(@validator)
        end


        private

        def build_graph(validator)
          if empty?
            return validator
          end
          build_graph(Dry::Validation.Schema(validator, {}, &shift))
        end
      end
    end
  end
end
