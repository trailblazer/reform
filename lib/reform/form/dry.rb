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
      def initialize(options = {})
        @schemas = []
        options ||= {}
        @schema_class = options[:schema] || Dry::Validation::Schema
        @schema_inject_params = options[:with] || {}
        @context = options[:context] || :object
      end

      def instance_exec(&block)
        @schemas << block
        @validator = Builder.new(@schemas.dup, @schema_class).validation_graph

        # inject the keys into the configure block automatically
        keys = @schema_inject_params.keys
        @validator.class_eval do
          configure do
            keys.each { |k| option k }
          end
        end unless keys.empty?
      end

      def call(form, reform_errors)
        # is there a better way to allow people to inject their form??
        # can't use 'self' as it would just return the class and not the instance.
        @schema_inject_params[:form] = form if @schema_inject_params[:form]

        dry_errors = @validator.new(@validator.rules, @schema_inject_params).call(input_hash(form)).messages

        process_errors(form, reform_errors, dry_errors)
      end

      # if dry_error is a hash rather than an array then it contains
      # the messages for a nested property
      # these messages need to be added to the correct collection
      # objects.

      # collections:
      # {0=>{:name=>["must be filled"]}, 1=>{:name=>["must be filled"]}}

      # Objects:
      # {:name=>["must be filled"]}
      # simply load up the object and attach the message to it
      def process_errors(form, reform_errors, dry_errors)
        dry_errors.each do |field, dry_error|
          add_error_message(field, dry_error, reform_errors) and next if dry_error.is_a?(Array)
          process_nested_errors(form.send(field), field, dry_error, reform_errors)
        end
      end

      def process_nested_errors(nested_form, field, dry_errors, reform_errors)
        if nested_form.is_a? Array
          dry_errors.each do |index, object_errors|
            process_nested_errors(nested_form[index], field, object_errors, reform_errors)
          end
        else
          process_errors(nested_form, nested_form.errors, dry_errors)
          reform_errors.merge!(nested_form.errors, [field])
        end
      end

      def add_error_message(field, attr_errors, reform_errors)
        attr_errors.each do |attr_error|
          reform_errors.add(field, attr_error)
        end
      end

      # we can't use to_nested_hash as it get's messed up by composition.
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
