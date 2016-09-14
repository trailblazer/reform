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
        @schema_inject_params = options[:with] || {}
        @context = options[:context] || :object
      end

      def instance_exec(&block)
        @schemas << block
        @validator = Builder.new(@schemas.dup, @schema_class).validation_graph
      end

      def call(form, reform_errors)
        with = {form: form }.merge(@schema_inject_params)

        dry_errors = @validator.new(@validator.rules, with).call(input_hash(form)).messages

        process_errors(form, reform_errors, dry_errors)
      end

      # if dry_error is a hash rather than an array then it contains
      # the messages for a collection
      # these messages need to be added to the correct collection
      # objects.

      # collections:  TODO: Correctly assign errors based on fragment index
      # {0=>{:name=>["must be filled"]}, 1=>{:name=>["must be filled"]}}
      # these index keys would match the fragment['index']

      # Objects:
      # {:name=>["must be filled"]}
      # simply load up the object and attach the message to it
      def process_errors(form, reform_errors, dry_errors)
        dry_errors.each do |field, dry_error|
          add_error_message(field, dry_error, reform_errors) and next if dry_error.is_a?(Array)
          add_nested_error_message(form, field, reform_errors, dry_error)
        end
      end

      def add_error_message(field, attr_errors, reform_errors)
        attr_errors.each do |attr_error|
          reform_errors.add(field, attr_error)
        end
      end

      def add_nested_error_message(form, field, reform_errors, dry_error)
        form.schema.each(twin: true) do |dfn|
          next if dfn[:name] != field.to_s
          # recursively add messages on nested form.
          Disposable::Twin::PropertyProcessor.new(dfn, form).() do |nested_form|
            if dfn[:collection]
              dry_error = dry_error[nested_form.parent.send(dfn[:name]).index(nested_form)]
              return if dry_error.nil? # if our fragment isn't in dry-errors then skip
            end
            nested_errors = nested_form.build_errors
            process_errors(nested_form, nested_errors, dry_error)

            reform_errors.merge!(nested_errors, [field]) # local errors.
            nested_form.errors.merge!(nested_errors, [])
          end
        end
      end

      # we can't use to_nested_hash has it get's messed up by composition.
      def input_hash(form)
        return form.input_params if @context == :params

        hash = form.class.nested_hash_representer.new(form).to_hash
        symbolize_hash(hash)
      end

      # dry-v needs symbolized keys
      # TODO: Don't do this here... Representers??
      def symbolize_hash(old_hash)
        old_hash.each_with_object({}) { |(k, v), new_hash|
          new_hash[k.to_sym] = if v.is_a?(Hash)
                             symbolize_hash(v)
                           elsif v.is_a?(Array)
                             v.map{ |h| h.is_a?(Hash) ? symbolize_hash(h) : h }
                           else
                             v
                           end
        }
      end

      class Builder < Array
        def initialize(array, schema_class)
          super(array)
          @validator = Dry::Validation.Schema(schema_class, build: false, &shift)
        end

        def validation_graph
          build_graph(@validator)
        end

        private

        def build_graph(validator)
          if empty?
            return validator
          end
          build_graph(Dry::Validation.Schema(validator, build: false, &shift))
        end
      end
    end
  end
end
