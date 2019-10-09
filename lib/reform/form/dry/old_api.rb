module Reform::Form::Dry
  module OldApi
    class Schema < Dry::Validation::Schema
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
          schema_class = options[:schema] || Reform::Form::Dry::OldApi::Schema
          @validator = Dry::Validation.Schema(schema_class, build: false)

          @schema_inject_params = options[:with] || {}
        end

        def instance_exec(&block)
          @validator = Dry::Validation.Schema(@validator, build: false, &block)
          # inject the keys into the configure block automatically
          keys = @schema_inject_params.keys
          @validator.class_eval do
            configure do
              keys.each { |k| option k }
            end
          end
        end

        def call(form)
          dynamic_options = {}
          dynamic_options[:form] = form if @schema_inject_params[:form]
          inject_options = @schema_inject_params.merge(dynamic_options)

          # TODO: only pass submitted values to Schema#call?
          dry_result = call_schema(inject_options, input_hash(form))
          # dry_messages    = dry_result.messages

          return dry_result

          _reform_errors = Reform::Contract::Errors.new(dry_result) # TODO: dry should be merged here.
        end

        private

        def call_schema(inject_options, input)
          @validator.new(@validator.rules, inject_options).(input)
        end
      end
    end
  end
end
