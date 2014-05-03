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

    inheritable_attr :features
    self.features = []


    module PropertyMethods
      extend Forwardable

      def property(name, options={}, &block)
        options[:private_name] = options.delete(:as)

        # at this point, :extend is a Form class.
        options[:features] = features if block_given?
        definition = representer_class.property(name, options, &block)
        setup_form_definition(definition) if block_given? or options[:form]

        create_accessor(name)
        definition
      end

      def collection(name, options={}, &block)
        options[:collection] = true

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


    def aliased_model
      # TODO: cache the Expose.from class!
      Reform::Expose.from(self.class.representer_class).new(:model => model)
    end

    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations

    require "reform/form/virtual_attributes"

    require 'reform/form/setup'
    include Setup
    require 'reform/form/validate'
    include Validate
    require 'reform/form/sync'
    include Sync
    require 'reform/form/save'
    include Save

    require 'reform/form/multi_parameter_attributes'
    include MultiParameterAttributes # TODO: make features dynamic.

    attr_accessor :model

  private
    attr_accessor :fields

    def mapper
      self.class.representer_class
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
