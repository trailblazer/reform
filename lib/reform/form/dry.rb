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
        @schemas = []
      end

      def instance_exec(&block)
        @schemas << block
        @validator = Builder.new(@schemas.dup).validation_graph
      end

      def call(form, options)
        # a message item looks like: {:confirm_password=>["size cannot be less than 2"]}
        if options[:with]
          @validator = @validator.with(options[:with].map {|k,v| [k, form.instance_exec(&v)] }.to_h)
        end
        @validator.call(form.to_nested_hash).messages
        .each do |field, dry_error|
          dry_error.each do |attr_error|
            form.errors.add(field, attr_error)
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
