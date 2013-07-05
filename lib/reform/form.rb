require 'forwardable'
require 'ostruct'

require 'reform/composition'

module Reform
  class Form
    extend Forwardable
    # reasons for delegation:
    # presentation: this object is used in the presentation layer by #form_for.
    # problem: #form_for uses respond_to?(:email_before_type_cast) which goes to an internal hash in the actual record.
    # validation: this object also contains the validation rules itself, should be separated.

    # Allows using property and friends in the Form itself. Forwarded to the internal representer_class.
    module PropertyMethods
      extend Forwardable

      def property(name, *args)
        representer_class.property(name, *args)
        create_accessor(name)
      end

      def properties(names, *args)
        names.each { |name| property(name, *args) }
      end

    #private
      def representer_class
        @representer_class ||= Class.new(Reform::Representer)
      end

      def create_accessor(name)
        delegate [name, "#{name}="] => :fields
      end
    end
    extend PropertyMethods


    def initialize(model)
      @model  = model # we need this for #save.
      @fields = setup_fields(model)  # delegate all methods to Fields instance.
    end

    def validate(params)
      # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.
      from_hash(params)

      res = valid?  # this validates on <Fields> using AM::Validations, currently.

      nested_forms.each do |form|
        unless form.valid? # FIXME: we have to call validate here, otherwise this works only one level deep.
          res = false # res &= form.valid?
          errors.add(form.name, form.errors.messages)
        end
      end

      res
    end

    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      mapper.new(model).from_hash(to_hash) # DISCUSS: move to Composition?
    end

    # Use representer to return current key-value form hash.
    def to_hash(*)
      mapper.new(self).to_hash
    end

    def to_nested_hash
      symbolize_keys(to_hash)
    end

  private
    attr_accessor :model, :fields

    def symbolize_keys(hash)
      hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

    def mapper
      self.class.representer_class
    end

    def setup_fields(model)
      representer = Class.new(mapper).new(model)

      if representer.send(:representable_attrs).last.name == "hit"
        attrs = representer.send(:representable_attrs)
        attr = attrs.last

        attr.options.merge!(
          :getter   => lambda { |*| NestedFormTest::AlbumForm::SongForm.new(hit) },
          :instance => false
          )

        representer.instance_variable_set(:@representable_attrs, attrs)
      end

      create_fields(representer.fields, representer.to_hash)
    end

    def create_fields(field_names, fields)
      Fields.new(field_names, fields)
    end

    def from_hash(params, *args)
      mapper.new(self).from_hash(params) # sets form properties found in params on self.
    end

    def nested_forms
      mapper.representable_attrs.
        find_all { |attr| attr.typed? }.
        collect  { |attr| send(attr.getter) } # DISCUSS: is there another way of getting the forms?
    end

    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations

    module Errors
      module MessagesMethod
        def messages
          self
        end
      end

      def errors
        return super unless ::ActiveModel::VERSION::MAJOR == 3 and ::ActiveModel::VERSION::MINOR == 0
        super.extend(MessagesMethod) # Rails 3.0 fix. move to VersionStrategy when we have more of these.
      end
    end
    include Errors
  end

  # Keeps values of the form fields. What's in here is to be displayed in the browser!
  # we need this intermediate object to display both "original values" and new input from the form after submitting.
  class Fields < OpenStruct
    def initialize(properties, values={})
      fields = properties.inject({}) { |hsh, attr| hsh.merge!(attr => nil) }
      super(fields.merge!(values))  # TODO: stringify value keys!
    end
  end


  require 'representable/hash'
  require 'representable/decorator'
  class Representer < Representable::Decorator
    include Representable::Hash

    # Returns hash of all property names.
    def fields
      representable_attrs.map(&:name)
    end
  end
end
