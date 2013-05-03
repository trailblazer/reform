require 'delegate'

module Reform
  class Form  < SimpleDelegator
    # reasons for delegation:
    # presentation: this object is used in the presentation layer by #form_for.
    # problem: #form_for uses respond_to?(:email_before_type_cast) which goes to an internal hash in the actual record.
    # validation: this object also contains the validation rules itself, should be separated.
    # TODO: figure out #to_key issues.

    def initialize(mapper, composition)
      @mapper     = mapper
      @model      = composition
      representer = @mapper.new(composition)

      super Fields.new(representer.fields, representer.to_hash)  # decorate composition and transform to hash.
    end

    def validate(params)
      # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.
      update_with(params)

      valid?  # this validates on <Fields> using AM::Validations, currently.
    end

    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      @mapper.new(model).from_hash(to_hash) # DISCUSS: move to Composition?
    end

  private
    attr_accessor :mapper, :model

    def update_with(params)
      mapper.new(self).from_hash(params) # sets form properties found in params on self.
    end

    # Use representer to return current key-value form hash.
    def to_hash
      mapper.new(self).to_hash
    end

    def to_nested_hash
      model.nested_hash_for(to_hash)  # use composition to compute nested hash.
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
        delegate *accessors, to: "@#{model}"
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

    def self.properties(names, *args)
      names.each do |name|
        property(name, *args)
      end
    end

    # Returns hash of all property names.
    def fields
      representable_attrs.collect { |cfg| cfg.name }
    end
  end
end