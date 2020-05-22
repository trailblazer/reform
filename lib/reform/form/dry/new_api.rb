::Dry::Validation.load_extensions(:hints)

module Reform::Form::Dry
  module NewApi

    class Contract < ::Dry::Validation::Contract
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
          @validator = options.fetch(:schema, Contract)
          @schema_inject_params = options.fetch(:with, {})
        end

        def instance_exec(&block)
          @block = block
        end

        def call(form)
          # when passing options[:schema] the class instance is already created so we just need to call
          # "call"
          if @validator.is_a?(Class) && @validator <= ::Dry::Validation::Contract
            dynamic_options = {form: form}
            inject_options = @schema_inject_params.merge(dynamic_options)
            @validator = @validator.build(inject_options, &@block)
          end

          @validator.call(input_hash(form))
        end
      end
    end
  end
end
