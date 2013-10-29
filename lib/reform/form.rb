require 'forwardable'
require 'ostruct'

require 'reform/composition'
require 'reform/representer'

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

      def property(name, options={}, &block)
        process_options(name, options, &block)

        definition = representer_class.property(name, options, &block)
        setup_form_definition(definition) if block_given?
        create_accessor(name)
      end

      def collection(name, options={}, &block)
        options[:form_collection] = true

        property(name, options, &block)
      end

      def properties(names, *args)
        names.each { |name| property(name, *args) }
      end

      def setup_form_definition(definition)
        definition.options[:form] = definition.options.delete(:extend)

        definition.options[:parse_strategy] = :sync
        definition.options[:instance] = true # just to make typed? work
      end

      def representer_class
        @representer_class ||= Class.new(Reform::Representer)
      end

    private
      def create_accessor(name)
        delegate [name, "#{name}="] => :fields
      end

      def process_options(name, options) # DISCUSS: do we need that hook?
      end
    end
    extend PropertyMethods


    def initialize(model)
      @model  = model # we need this for #save.
      @fields = setup_fields(model)  # delegate all methods to Fields instance.
    end

    module ValidateMethods # TODO: introduce Base module.
      def validate(params)
        # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.
        from_hash(params)

        res = valid?  # this validates on <Fields> using AM::Validations, currently.
        #inject(true) do |res, form| # FIXME: replace that!
        mapper.new(@fields).nested_forms do |attr, form| #.collect { |attr, form| nested[attr.from] = form }
          res = validate_for(form, res, attr.from)
        end

        res
      end

    private
      def validate_for(form, res, prefix=nil)
        return res if form.valid? # FIXME: we have to call validate here, otherwise this works only one level deep.

        errors.merge!(form.errors, prefix)
        false
      end

    end
    include ValidateMethods

    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      save_to_models
    end

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
      mapper.new(self).from_hash(params) # sets form properties found in params on self.
    end

    def errors
      @errors ||= Errors.new(self)
    end

    attr_accessor :model

    # 1) initialize -> setup fields -> Setup#to_hash
  private
    attr_accessor :fields

    def mapper
      self.class.representer_class
    end

    def setup_fields(model)
      representer = mapper.new(model).extend(Setup::Representer)

      create_fields(representer.fields, representer.to_hash)
    end

    #representer.to_hash override: { write: lambda { |doc, value|  } }

    # DISCUSS: this would be cool in representable:
    # to_hash(hit: lambda { |value| form_class.new(..) })

    # steps:
    # - bin.get
    # - map that: Forms.new( orig ) <-- override only this in representable (how?)
    # - mapped.to_hash


    def create_fields(field_names, fields)
      Fields.new(field_names, fields)
    end


    # Mechanics for writing input to model.
    module Sync
      module EmptyAttributesOptions
        def options # DISCUSS: why use the standard representer here? we should use it everywhere.
          empty_fields = representable_attrs.
            find_all { |d| d.options[:empty] }.
            collect  { |d| d.name.to_sym }

          super.exclude!(empty_fields)
        end
      end

      module ReadonlyAttributesOptions
        def options
          readonly_fields = representable_attrs.
            find_all { |d| d.options[:virtual] }.
            collect  { |d| d.name.to_sym }

          super.exclude!(readonly_fields)
        end
      end

      # Writes input to model.
      module Representer
        def from_hash(*)
          nested_forms do |attr, model|
            attr.options.merge!(
              :decorator => attr.options[:form].representer_class
            )

            if attr.options[:form_collection]
              attr.options.merge!(
                :collection => true
              )
            end
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

    # Mechanics for setting up initial Field values.
    module Setup
      module Representer
        include Reform::Representer::WithOptions
        include Sync::EmptyAttributesOptions

        def to_hash(*)
          setup_nested_forms

          super # TODO: allow something like super(:exclude => empty_fields)
        end

      private
        def setup_nested_forms
          nested_forms do |attr, model|
            form_class = attr.options[:form]

            attr.options.merge!(
              :getter   => lambda do |*|
                nested_model  = send(attr.getter) # decorated.hit # TODO: use bin.get

                if attr.options[:form_collection]
                  Forms.new(nested_model.collect { |mdl| form_class.new(mdl)})
                else
                  form_class.new(nested_model)
                end
              end,
              :instance => false, # that's how we make it non-typed?.
            )
          end
        end
      end
    end

    def save_to_models # TODO: rename to #sync_models
      representer = mapper.new(model)

      representer.extend(Sync::Representer)

      input_representer = mapper.new(self).extend(Sync::InputRepresenter)

      representer.from_hash(input_representer.to_hash)
    end

    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations

    # The Errors class is planned to replace AM::Errors. It provides proper nested error messages.
    class Errors < ActiveModel::Errors
      def messages
        return super unless Reform.rails3_0?
        self
      end

      # def each
      #   messages.each_key do |attribute|
      #     self[attribute].each { |error| yield attribute, Array.wrap(error) }
      #   end
      # end

      def merge!(errors, prefix=nil)
        # TODO: merge into AM.
        errors.messages.each do |field, msgs|
          field = "#{prefix}.#{field}" if prefix

          msgs = [msgs] if Reform.rails3_0? # DISCUSS: fix in #each?

          msgs.each do |msg|
            next if messages[field] and messages[field].include?(msg)
            add(field, msg)
          end # Forms now contains a plain errors hash. the errors for each item are still available in item.errors.
        end
      end
    end

    require "representable/hash/collection"
    require 'active_model'
    class Forms < Array # DISCUSS: this should be a Form subclass.
      include Form::ValidateMethods

      def valid?
        inject(true) do |res, form|
          res = validate_for(form, res)
        end
      end

      def errors
        @errors ||= Form::Errors.new(self)
      end

      # this gives us each { to_hash }
      include Representable::Hash::Collection
      items :parse_strategy => :sync, :instance => true
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
