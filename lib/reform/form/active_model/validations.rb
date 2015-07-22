require "active_model"
require "reform/form/active_model/errors"
require "uber/delegates"

module Reform::Form::ActiveModel
  # AM::Validations for your form.
  #
  # Note: The preferred way for validations should be Lotus::Validations, as ActiveModel::Validation's
  # implementation is old, very complex given that it needs to do a simple thing, is using
  # globals like @errors, and relies and more than 100 methods to be mixed into your form.
  #
  # Implements ::validates and friends, and #valid?.
  #
  module Validations
    def self.included(includer)
      includer.instance_eval do
        include Reform::Form::ActiveModel
        extend Uber::InheritableAttr
        inheritable_attr :validator
        self.validator = Class.new(Validator)

        class << self
          extend Uber::Delegates
          delegates :validator, :validates, :validate, :validates_with, :validate_with

          # Hooray! Delegate translation back to Reform's Validator class which contains AM::Validations.
          delegates :validator, :human_attribute_name, :lookup_ancestors, :i18n_scope # Rails 3.1.
        end
      end
    end

    def build_errors
      Reform::Contract::Errors.new(self)
    end

    # The concept of "composition" has still not arrived in Rails core and they rely on 400 methods being
    # available in one object. This is why we need to provide parts of the I18N API in the form.
    def read_attribute_for_validation(name)
      send(name)
    end


    # Validators is the validatable object. On the class level, we define validations,
    # on instance, it exposes #valid?.
    class Validator
      # current i18n scope: :activemodel.
      include ActiveModel::Validations

      class << self
        def model_name
          @_active_model_sucks || ActiveModel::Name.new(Reform::Form, nil, "Reform::Form")
        end

        def model_name=(name)
          @_active_model_sucks = name
        end

        def clone
          Class.new(self)
        end
      end

      def initialize(form, name)
        @form = form
        self.class.model_name = name # one of the many reasons why i will drop support for AM::V in 2.1.
      end

      def method_missing(method_name, *args, &block)
        @form.send(method_name, *args, &block)
      end
    end

    private

    # Needs to be implemented by every validation backend and implements the
    # actual validation. See Reform::Form::Lotus, too!
    def valid?
      # we always pass the model_name into the validator now, so AM:V can do its magic. problem is that
      # AM does validator.class.model_name so we have to hack the dynamic model name into the
      # Validator class.
      validator = self.class.validator.new(self, model_name)
      validator.valid? # run the Validations object's validator with the form as context. this won't pollute anything in the form.


      #errors.merge!(validator.errors, "")
      validator.errors.each do |name, error| # TODO: handle with proper merge, or something. validator.errors is ALWAYS AM::Errors.
        errors.add(name, error)
      end

      errors.empty?
    end
  end
end
