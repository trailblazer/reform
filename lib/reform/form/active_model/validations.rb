require "active_model"
require "reform/form/active_model/errors"
require "uber/delegates"

module Reform::Form::ActiveModel
  # AM::Validations for your form.
  #
  # Note: The preferred way for validations should be Lotus::Validations, as ActiveModel::Validation's implementation is
  # old, very complex given that it needs to do a simple thing, and it's using globals like @errors.
  #
  # Implements ::validates and friends, and #valid?.
  module Validations
    def self.included(includer)
      includer.instance_eval do
        extend Uber::InheritableAttr
        inheritable_attr :validator
        self.validator = Class.new(Validator)

        class << self
          extend Uber::Delegates
          delegates :validator, :validates, :validate, :validates_with, :validate_with
        end
      end
    end

    def build_errors
      Reform::Contract::Errors.new(self)
    end


    # Validators is the validatable object. On the class level, we define validations,
    # on instance, it exposes #valid?.
    class Validator
      # current i18n scope: :activemodel.

      include ActiveModel::Validations
      # extend ActiveModel::Naming

      def initialize(form)
        @form = form
      end

      def method_missing(method_name, *args, &block)
        @form.send(method_name, *args, &block)
      end

      # def self.model_name # FIXME: this is only needed for i18n, it seems.
      #   "Reform::Form"
      # end
      def self.model_name
        ActiveModel::Name.new(Reform::Form)
      end
      # we can also do self.name and return "reform/form" but then run into "wrong constant name reform/form" from the autoloader. wtf?

      def self.clone
        Class.new(self)
      end
    end


    def valid?
      validator = self.class.validator.new(self)
      validator.valid? # run the Validations object's validator with the form as context. this won't pollute anything in the form.


      #errors.merge!(validator.errors, "")
      validator.errors.each do |name, error| # TODO: handle with proper merge, or something. validator.errors is ALWAYS AM::Errors.
        errors.add(name, error)
      end

      errors.empty?
    end
  end
end