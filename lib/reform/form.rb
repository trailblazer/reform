require 'forwardable'
require 'ostruct'

module Reform
  class Form
    extend Forwardable
    # reasons for delegation:
    # presentation: this object is used in the presentation layer by #form_for.
    # problem: #form_for uses respond_to?(:email_before_type_cast) which goes to an internal hash in the actual record.
    # validation: this object also contains the validation rules itself, should be separated.
    # TODO: figure out #to_key issues.

    module PropertyMethods
      extend Forwardable
      delegate [:property] => :representer_class

      def properties(names, *args)
        names.each { |name| property(name, *args) }
      end

    #private
      def representer_class
        @representer_class ||= Class.new(Reform::Representer)
      end
    end
    extend PropertyMethods


    def initialize(composition)
      @model = composition

      setup_fields(self.class.representer_class, composition)  # delegate all methods to Fields instance.
    end

    def validate(params)
      # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.
      update_with(params)

      valid?  # this validates on <Fields> using AM::Validations, currently.
    end

    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      mapper.new(model).from_hash(to_hash) # DISCUSS: move to Composition?
    end

    # Use representer to return current key-value form hash.
    def to_hash
      mapper.new(self).to_hash
    end

    def to_nested_hash
      model.nested_hash_for(to_hash)  # use composition to compute nested hash.
    end

  private
    attr_accessor :model

    def mapper # FIXME.
      self.class.representer_class
    end

    def setup_fields(mapper_class, composition)
      # decorate composition and transform to hash.
      representer = mapper_class.new(composition)

      create_accessors(representer.fields)

      create_fields(representer.fields, representer.to_hash)
    end

    def create_fields(field_names, fields)
      Fields.new(field_names, fields)
    end

    def create_accessors(fields) # TODO: make this on class level!
      writers = fields.collect { |fld| "#{fld}=" }
      self.class.delegate fields+writers => :@model
    end

    def update_with(params)
      mapper.new(self).from_hash(params) # sets form properties found in params on self.
    end

    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations
  end

  # Keeps values of the form fields. What's in here is to be displayed in the browser!
  # we need this intermediate object to display both "original values" and new input from the form after submitting.
  class Fields < OpenStruct
    def initialize(properties, values={})
      fields = properties.inject({}) { |hsh, attr| hsh.merge!(attr => nil) }
      super(fields.merge!(values))  # TODO: stringify value keys!
    end
  end

  # Keeps composition of models and knows how to transform a plain hash into a nested hash.
  class Composition
    class << self
      def map(options)
        @attr2obj = {}  # {song: ["title", "track"], artist: ["name"]}

        options.each do |mdl, meths|
          create_accessors(mdl, meths)
          attr_reader mdl # FIXME: unless already defined!!

          meths.each { |m| @attr2obj[m.to_s] = mdl }
        end
      end

      # Specific to representable.
      def map_from(representer)
        options = {}
        representer.representable_attrs.each do |cfg|
          options[cfg.options[:on]] ||= []
          options[cfg.options[:on]] << cfg.name
        end

        map options
      end

      def model_for_property(name)
        @attr2obj.fetch(name.to_s)
      end

    private
      def create_accessors(model, methods)
        accessors = methods.collect { |m| [m, "#{m}="] }.flatten
        delegate *accessors << {:to => :"#{model}"}
      end
    end

    # TODO: make class method?
    def nested_hash_for(attrs)
      {}.tap do |hsh|
        attrs.each do |name, val|
          obj = self.class.model_for_property(name)
          hsh[obj] ||= {}
          hsh[obj][name.to_sym] = val
        end
      end
    end

    def initialize(models)
      models.each do |name, obj|
        instance_variable_set(:"@#{name}", obj)
      end
    end
  end

  require 'representable/hash'
  class Representer < Representable::Decorator
    include Representable::Hash



    # Returns hash of all property names.
    def fields
      representable_attrs.collect { |cfg| cfg.name }
    end
  end
end
