require 'forwardable'
require 'ostruct'

require 'reform/composition'
require 'reform/representer'

require 'uber/inheritable_attr'


module Reform
  class Form
    extend Forwardable

    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Reform::Representer)


    module PropertyMethods
      extend Forwardable

      def property(name, options={}, &block)
        # at this point, :extend is a Form class.
        definition = representer_class.property(name, options, &block)
        setup_form_definition(definition) if block_given? or options[:form]

        create_accessor(name)
        definition
      end

      def collection(name, options={}, &block)
        options[:collection] =true

        property(name, options, &block)
      end

      def properties(names, *args)
        names.each { |name| property(name, *args) }
      end

      def setup_form_definition(definition)
        options = {
          :form         => definition[:form] || definition[:extend].evaluate(nil), # :form is always just a Form class name.
          :pass_options => true, # new style of passing args
          :prepare      => lambda { |form, args| form }, # always just return the form without decorating.
        }

        definition.merge!(options)
      end

    private
      def create_accessor(name)
        # Make a module that contains these very accessors, then include it
        # so they can be overridden but still are callable with super.
        accessors = Module.new do
          extend Forwardable # DISCUSS: do we really need Forwardable here?
          delegate [name, "#{name}="] => :fields
        end
        include accessors
      end
    end
    extend PropertyMethods


    def initialize(model)
      @model  = model # we need this for #save.
      @fields = setup_fields(model)  # delegate all methods to Fields instance.
    end


    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations

    require 'reform/form/validate'
    include Validate

    require 'reform/form/multi_parameter_attributes'
    include MultiParameterAttributes # TODO: make features dynamic.

    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      sync_to_models
    end
    alias_method :sync, :save # TODO: make it two separate concerns.

    # Use representer to return current key-value form hash.
    def to_hash(*args)
      mapper.new(self).to_hash(*args)
    end

    require "active_support/hash_with_indifferent_access" # DISCUSS: replace?
    def to_nested_hash
      map = mapper.new(self)

      ActiveSupport::HashWithIndifferentAccess.new(map.to_hash)
    end

    def from_hash(params, *args)
      mapper.new(self).extend(Validate::Representer).from_hash(params) # sets form properties found in params on self and nested forms.
    end

    def errors
      @errors ||= Errors.new(self)
      @errors
    end

    attr_accessor :model

  private
    attr_accessor :fields

    def mapper
      self.class.representer_class
    end

    def setup_fields(model)
      representer = mapper.new(model).extend(Setup::Representer)

      create_fields(representer.fields, representer.to_hash)
    end

    def create_fields(field_names, fields)
      Fields.new(field_names, fields)
    end


    require "reform/form/virtual_attributes"

    # Mechanics for setting up initial Field values.
    module Setup
      module Representer
        include Reform::Representer::WithOptions
        include EmptyAttributesOptions

        def to_hash(*)
          setup_nested_forms

          super # TODO: allow something like super(:exclude => empty_fields)
        end

      private
        def setup_nested_forms
          nested_forms do |attr|
            attr.merge!(
              :representable => false, # don't call #to_hash.
              :prepare       => lambda do |model, args|
                args.binding[:form].new(model)
              end
            )
          end
        end
      end
    end

    # Mechanics for writing input to model.
    module Sync
      # Writes input to model.
      module Representer
        def from_hash(*)
          nested_forms do |attr|
            attr.merge!(
              :extend         => attr[:form].representer_class, # we actually want decorate the model.
              :parse_strategy => :sync,
              :collection     => attr[:collection]
            )
            attr.delete(:prepare)
          end

          super
        end
      end

      # Transforms form input into what actually gets written to model.
      module InputRepresenter
        include Reform::Representer::WithOptions
        # TODO: make dynamic.
        include EmptyAttributesOptions
        include ReadonlyAttributesOptions
      end
    end


    ### TODO: add ToHash with :prepare => lambda { |form, args| form },


    def sync_to_models # TODO: rename to #sync_models
      representer = mapper.new(model).extend(Sync::Representer)

      input_representer = mapper.new(self).extend(Sync::InputRepresenter)

      representer.from_hash(input_representer.to_hash)
    end
  end


  # Keeps values of the form fields. What's in here is to be displayed in the browser!
  # we need this intermediate object to display both "original values" and new input from the form after submitting.
  class Fields < OpenStruct
    def initialize(properties, values={})
      fields = properties.inject({}) { |hsh, attr| hsh.merge!(attr => nil) }
      super(fields.merge!(values))  # TODO: stringify value keys!
    end
  end

  def self.rails3_0?
    ::ActiveModel::VERSION::MAJOR == 3 and ::ActiveModel::VERSION::MINOR == 0
  end
end
