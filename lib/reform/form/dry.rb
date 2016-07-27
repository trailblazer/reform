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

    class DrySchema < Dry::Validation::Schema
      configure do |config|
        option :form
      end
    end

    class Group
      def initialize(options = {})
        @schemas = []
        options ||= {}
        @schema_class = options[:schema_class] || DrySchema
      end

      def instance_exec(&block)
        @schemas << block
        @validator = Builder.new(@schemas.dup, @schema_class).validation_graph
      end

      # FIXME: This doesn't work with compositions as the default implementaion of to_nested_hash
      # messes with the input hash structure.
      def call(form, reform_errors)
        # a message item looks like: {:confirm_password=>["confirm_password size cannot be less than 2"]}
        # dry-v needs symbolized keys
        dry_nested_hash = symbolize_fields(form.to_nested_hash)

        @validator.with(form: form).call(dry_nested_hash).messages.each do |field, dry_error|
          dry_error.each do |attr_error|
            reform_errors.add(field, attr_error)
          end
        end
      end

      # TODO: Don't do this here... Representers??
      def symbolize_fields(hash)
        hash.each_with_object({}) { |(k, v), hash|
          hash[k.to_sym] = v.is_a?(Hash) ? symbolize_fields(v) : v
        }
      end

      class Builder < Array
        def initialize(array, schema_class = ReformSchema)
          super(array)
          @validator = Dry::Validation.Schema(schema_class, &shift)
        end

        def validation_graph
          build_graph(@validator)
        end

        private

        def build_graph(validator)
          if empty?
            return validator
          end
          build_graph(Dry::Validation.Schema(validator, &shift))
        end
      end
    end
  end
end
