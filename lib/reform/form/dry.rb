require "dry-validation"
require "dry/validation/schema/form"
require "reform/validation"

module Reform::Form::Dry
  class Schema < Dry::Validation::Schema
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
      def initialize(options = {})
        options ||= {}
        schema_class = options[:schema] || Reform::Form::Dry::Schema
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
        inject_options  = @schema_inject_params.merge(dynamic_options)

        # TODO: only pass submitted values to Schema#call?
        dry_result      = call_schema(inject_options, input_hash(form))
        # dry_messages    = dry_result.messages

        return dry_result
        reform_errors   = Reform::Contract::Errors.new(dry_result) # TODO: dry should be merged here.
      end

    private
      def call_schema(inject_options, input)
        @validator.new(@validator.rules, inject_options).(input)
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

      # we can't use to_nested_hash as it get's messed up by composition.
      def input_hash(form)
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
    end
  end
end
