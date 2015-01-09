require 'forwardable'
require 'uber/inheritable_attr'
require 'uber/delegates'
require 'ostruct'

require 'reform/representer'

module Reform
  # Gives you a DSL for defining the object structure and its validations.
  class Contract # DISCUSS: make class?
    extend Uber::Delegates

    extend Uber::InheritableAttr
    # representer_class gets inherited (cloned) to subclasses.
    inheritable_attr :representer_class
    self.representer_class = Reform::Representer.for(:form_class => self) # only happens in Contract/Form.
    # this should be the only mechanism to inherit, features should be stored in this as well.


    # each contract keeps track of its features and passes them onto its local representer_class.
    # gets inherited, features get automatically included into inline representer.
    # TODO: the representer class should handle that, e.g. in options (deep-clone when inheriting.)
    inheritable_attr :features
    self.features = {}


    RESERVED_METHODS = [:model, :aliased_model, :fields, :mapper] # TODO: refactor that so we don't need that.


    module PropertyMethods
      def property(name, options={}, &block)
        deprecate_as!(options)
        options[:private_name] = options.delete(:from)
        options[:coercion_type] = options.delete(:type)
        options[:features] ||= []
        options[:features] += features.keys if block_given?
        options[:pass_options] = true

        # readable and writeable is true as it's not == false

        if reform_2_0
          if options.delete(:virtual)
            options[:_readable]  = false
            options[:_writeable] = false
          else
            options[:_readable]  = options.delete(:readable)
            options[:_writeable] = options.delete(:writeable)
          end

        else # TODO: remove me in 2.0.
          deprecate_virtual_and_empty!(options)
        end

        validates(name, options.delete(:validates).dup) if options[:validates]

        definition = representer_class.property(name, options, &block)
        setup_form_definition(definition) if block_given? or options[:form]

        create_accessor(name)
        definition
      end

      def properties(*args)
        options = args.extract_options!

        if args.first.is_a? Array # TODO: REMOVE in 2.0.
          warn "[Reform] Deprecation: Please pass a list of names instead of array to ::properties, like `properties :title, :id`."
          args = args.first
        end
        args.each { |name| property(name, options.dup) }
      end

      def collection(name, options={}, &block)
        options[:collection] = true

        property(name, options, &block)
      end

      def setup_form_definition(definition)
        options = {
          # TODO: make this a bit nicer. why do we need :form at all?
          :form         => (definition.representer_module) || definition[:form], # :form is always just a Form class name.
          :pass_options => true, # new style of passing args
          :prepare      => lambda { |form, args| form }, # always just return the form without decorating.
          :representable => true, # form: Class must be treated as a typed property.
        }

        definition.merge!(options)
      end

    private

      def create_accessor(name)
        handle_reserved_names(name)

        delegates :fields, name, "#{name}=" # Uber::Delegates
      end

      def handle_reserved_names(name)
        raise "[Reform] the property name '#{name}' is reserved, please consider something else using :as." if RESERVED_METHODS.include?(name)
      end
    end
    extend PropertyMethods


    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations



    attr_accessor :model

    require 'reform/contract/setup'
    include Setup

    def self.representers # keeps all transformation representers for one class.
      @representers ||= {}
    end

    def self.representer(name=nil, options={}, &block)
      return representer_class.each(&block) if name == nil
      return representers[name] if representers[name] # don't run block as this representer is already setup for this form class.

      only_forms = options[:all] ? false : true
      base       = options[:superclass] || representer_class

      representers[name] = Class.new(base).each(only_forms, &block) # let user modify representer.
    end

    require 'reform/contract/validate'
    include Validate

    def errors # FIXME: this is needed for Rails 3.0 compatibility.
      @errors ||= Errors.new(self)
    end


  private
    attr_accessor :fields
    attr_writer :errors # only used in top form. (is that true?)

    def mapper # FIXME: do we need this with class-level representers?
      self.class.representer_class
    end

    def self.deprecate_as!(options) # TODO: remove me in 2.0.
      return unless as = options.delete(:as)
      options[:from] = as
      warn "[Reform] The :as options got renamed to :from. See https://github.com/apotonick/reform/wiki/Migration-Guide and have a nice day."
    end

    def self.deprecate_virtual_and_empty!(options) # TODO: remove me in 2.0.
      if options.delete(:virtual)
        warn "[Reform] The :virtual option has changed! Check https://github.com/apotonick/reform/wiki/Migration-Guide and have a good day."
        options[:_readable] = true
        options[:_writeable] = false
      end

      if options[:empty]
        warn "[Reform] The :empty option has changed! Check https://github.com/apotonick/reform/wiki/Migration-Guide and have a good day."
        options[:_readable]  = false
        options[:_writeable] = false
      end
    end

    def self.register_feature(mod)
      features[mod] = true
    end

    # allows including representers from Representable, Roar or disposable.
    def self.inherit_module!(representer) # called from Representable::included.
      # representer_class.inherit_module!(representer)
      representer.representable_attrs.each do |dfn|
        next if dfn.name == "links" # wait a second # FIXME what is that?

        # TODO: remove manifesting and do that in representable, too!
        args = [dfn.name, dfn.instance_variable_get(:@options)] # TODO: dfn.to_args (inluding &block)

        property(*args) and next unless dfn.representer_module
        property(*args) { include dfn.representer_module } # nested.
      end
    end

    def self.clone
      Class.new(self)
    end

    require 'reform/schema'
    extend Schema

    alias_method :aliased_model, :model

    module Readonly
      def readonly?(name)
        options_for(name)[:writeable] == false
      end

      def options_for(name)
        self.class.representer_class.representable_attrs.get(name)
      end
    end
    include Readonly

    # TODO: remove me in 2.0.
    module Reform20Switch
      def self.included(base)
        base.register_feature(Reform20Switch)
      end
    end
    def self.reform_2_0!
      include Reform20Switch
    end
    def self.reform_2_0
      features[Reform20Switch]
    end


    # Keeps values of the form fields. What's in here is to be displayed in the browser!
    # we need this intermediate object to display both "original values" and new input from the form after submitting.
    class Fields < OpenStruct
      def initialize(properties, values={})
        fields = properties.inject({}) { |hsh, attr| hsh.merge!(attr => nil) }
        super(fields.merge!(values))  # TODO: stringify value keys!
      end
    end # Fields
  end
end

require 'reform/contract/errors'
