require "dry-validation"
require "dry/validation/schema/form"
require "reform/validation"

module Reform::Form::Dry
  def self.included(includer)
    includer.send :include, Validations
    includer.extend Validations::ClassMethods
  end

  class Schema < Dry::Validation::Schema
    configure do |config|
      option :form
    end
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
      def initialize(options = {})
        @schemas = []
        options ||= {}
        @schema_class = options[:schema] || Schema
      end

      def instance_exec(&block)
        @schemas << block
        @validator = Builder.new(@schemas.dup, @schema_class).validation_graph
      end

      def call(form, reform_errors)
        # a message item looks like: {:confirm_password=>["size cannot be less than 2"]}
        @validator.with(form: form).call(input_hash(form)).messages.each do |field, dry_error|
          dry_error.each do |attr_error|
            reform_errors.add(field, attr_error)
          end
        end
      end

      # we can't use to_nested_hash has it get's messed up by composition.
      def input_hash(form)
        hash = form.class.nested_hash_representer.new(form).to_hash
        symbolize_hash(hash)
      end

      # dry-v needs symbolized keys
      # TODO: Don't do this here... Representers??
      def symbolize_hash(hash)
        hash.each_with_object({}) { |(k, v), hash|
          hash[k.to_sym] = if v.is_a?(Hash)
                             symbolize_hash(v)
                           elsif v.is_a?(Array)
                             v.map{ |h| symbolize_hash(h) }
                           else
                             v
                           end
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
