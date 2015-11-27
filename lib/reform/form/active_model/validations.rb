require "active_model"
require "reform/form/active_model/errors"
require "uber/delegates"

module Reform::Form::ActiveModel
  # AM::Validations for your form.
  #
  # Provides ::validates, ::validate, #validate, and #valid?.
  module Validations
    def self.included(includer)
      includer.instance_eval do
        include Reform::Form::ActiveModel

        class << self
          extend Uber::Delegates
          # # Hooray! Delegate translation back to Reform's Validator class which contains AM::Validations.
          delegates :active_model_really_sucks, :human_attribute_name, :lookup_ancestors, :i18n_scope # Rails 3.1.

          # def validates(*args, &block)
          #   heritage.record(:validates, *args, &block)
          #   super(*Declarative::DeepDup.(args), &block) # FIX for Rails 3.1.
          # end

          def validation_group_class
            Group
          end

          def active_model_really_sucks
            Class.new(Validator)
          end

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

    class Group
      def initialize
        @validations = Class.new(Reform::Form::ActiveModel::Validations::Validator)
      end

      extend Uber::Delegates
      delegates :@validations, :validates, :validate, :validates_with, :validate_with

      def call(fields, errors, form) # FIXME.
        validator = @validations.new(form)
        validator.valid?

        validator.errors.each do |name, error| # TODO: handle with proper merge, or something. validator.errors is ALWAYS AM::Errors.
          errors.add(name, error)
        end
      end
    end


    # Validator is the validatable object. On the class level, we define validations,
    # on instance, it exposes #valid?.
    require "delegate"
    class Validator < SimpleDelegator
      # current i18n scope: :activemodel.
      include ActiveModel::Validations

      class << self
        def model_name
          @_active_model_sucks || ActiveModel::Name.new(Reform::Form, nil, "Reform::Form")
        end

        def model_name=(name)
          @_active_model_sucks = name
        end
      end

      def initialize(form)
        super(form)
        self.class.model_name = form.model_name # one of the many reasons why i will drop support for AM::V in 2.1. or maybe a bit later.
      end

      def method_missing(m, *args, &block)
        __getobj__.send(m, *args, &block) # send all methods to the form, even privates.
      end
    end
  end
end
