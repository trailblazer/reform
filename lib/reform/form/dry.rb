gem 'dry-validation'
require "dry-validation"
require "reform/validation"

::Dry::Validation.load_extensions(:hints)

module Reform::Form::Dry
  class Contract < Dry::Validation::Contract
  end

  def self.included(includer)
    includer.send :include, Validations
    includer.extend Validations::ClassMethods
  end

  module Validations
    module ClassMethods
      def validation_group_class
        Group
      end
    end

    def self.included(includer)
      includer.extend(ClassMethods)
    end

    class Group
      def initialize(options)
        @validator = options.fetch(:contract, Contract)
        @schema_inject_params = options.fetch(:with, {})
      end

      # attr_reader :validator, :schema_inject_params, :block

      def instance_exec(&block)
        @block = block
      end

      def call(form, deserialized_form)
        values = deserialized_form.to_input_hash # currently, this returns {@populated_instance}

        # when passing options[:schema] the class instance is already created so we just need to call
        # "call"
        return @validator.call(values) unless @validator.is_a?(Class) && @validator <= ::Dry::Validation::Contract

        dynamic_options = {form: form}
        inject_options = @schema_inject_params.merge(dynamic_options)
        contract.new(**inject_options).call(values)
      end

      def contract
        @contract ||= Class.new(@validator, &@block)
      end
    end
  end
end
