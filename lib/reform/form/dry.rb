require "dry-validation"
require "reform/validation"
require "reform/form/dry/input_hash"

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
      include InputHash

      def initialize(options = {})
        options ||= {}
        @validator = options[:schema] || Reform::Form::Dry::Contract

        @schema_inject_params = options[:with] || {}
      end

      def instance_exec(&block)
        Dry::Validation.load_extensions(:hints)
        @block = block
      end

      def call(form)
        dynamic_options = {}
        dynamic_options[:form] = form if @schema_inject_params[:form]
        inject_options = @schema_inject_params.merge(dynamic_options)

        Dry::Schema::DSL.class_eval do
          inject_options.each do |key, value|
            define_method(key) { value }
          end
        end

        # when passing options[:schema] the class instance is already created so we just need to call
        # "call"
        @validator = @validator.build(&@block) if @validator == Reform::Form::Dry::Contract

        # TODO: only pass submitted values to Schema#call?
        dry_result = @validator.call(input_hash(form))
        # dry_messages    = dry_result.messages

        return dry_result

        _reform_errors = Reform::Contract::Errors.new(dry_result) # TODO: dry should be merged here.
      end
    end
  end
end
