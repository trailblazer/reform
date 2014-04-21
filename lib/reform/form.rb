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
        process_options(name, options, &block)

        # at this point, :extend is a Form class.
        definition = representer_class.property(name, options, &block)
        setup_form_definition(definition) if block_given? or options[:form]

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

      def process_options(name, options) # DISCUSS: do we need that hook?
      end
    end
    extend PropertyMethods


    def initialize(model)
      @model  = model # we need this for #save.
      @fields = setup_fields(model)  # delegate all methods to Fields instance.
    end


        # Mechanics for writing to forms in #validate.
    module Validate
      module Representer
        def from_hash(*)
          # puts "+++++++++++++++++++++++ from_hash in #{self.inspect}"
          nested_forms do |attr|
            attr.delete(:prepare)
            attr.delete(:extend)

            attr.merge!(
              :collection => attr[:form_collection], # TODO: Def#merge! doesn't consider :collection if it's already set in attr YET.
              :parse_strategy => :sync, # just use nested objects as they are.
              :deserialize_method => :validate!,
            )
          end

          super
        end
      end

      module Populator
        def from_hash(params, *args)
          populated_attrs = []

          nested_forms do |attr|
            next unless attr[:populator]

            attr.merge!(
              :parse_strategy => attr[:populator],
              :representable  => false
              )
            populated_attrs << attr.name.to_sym
          end

          super(params, {:include => populated_attrs})
        end
      end
    end
    module ValidateMethods # TODO: introduce Base module.
      def validate(params)

        options = {:errors => errs = Errors.new(nil)}


        validate!(params, options, path)


        self.errors = errs # if the AM valid? API wouldn't use a "global" variable this would be better.


         puts "after merge: #{self.errors.messages.inspect}"

        # res
      end

    private
      attr_writer :errors # only used in top form.
      def validate!(params, options)
        populate!(params)

        # populate nested properties
        # update attributes of forms (from_hash)
        # run validate(errors) for all forms (no 1-level limitation anymore)

        # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.

        # sets scalars and recurses #validate.
        mapper.new(self).extend(Validate::Representer).from_hash(params, options) # calls validate(..) on nested.

        res = valid?  # this validates on <Fields> using AM::Validations, currently.
# puts "after vali in #{self}:: #{opts[:errors].messages.inspect}"


        #inject(true) do |res, form| # FIXME: replace that!
        # mapper.new(@fields).nested_forms do |attr| #.collect { |attr, form| nested[attr.from] = form }
        #   form = send(attr.name)
        #   next unless form # FIXME: this happens when the model's reader returns nil (property :song => nil). this shouldn't be considered by nested_forms!
        #   res = validate_for(form, res, attr.name)
        # end
        # puts "in #{self}, merging errors #{self.errors.messages.inspect}" unless opts[:errors ] == self.errors

        options[:errors].merge!(self.errors, prefix="blaaaa")
      #   return res if form.valid? # FIXME: we have to call validate here, otherwise this works only one level deep.

      #   errors.merge!(form.errors, prefix)
      #   false
       end

      def populate!(params)
        mapper.new(self).extend(Validate::Populator).from_hash(params)
      end
    end
    include ValidateMethods
    require 'reform/form/multi_parameter_attributes'
    ###include MultiParameterAttributes # TODO: make features dynamic.

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

            options = {
              #:exec_context  => :decorator, # call blocks etc in this context.
              :representable => false, # don't call #to_hash.

              :prepare       => lambda do |model, args|
                attr       = args.binding
                form_class = attr[:form] # non-dynamic option.

                if attr[:form_collection]
                  model ||= []
                  Forms.new(model.collect { |mdl| form_class.new(mdl)}, attr)
                else
                  next unless model # DISCUSS: do we want that?
                  form_class.new(model)
                end
              end
            }

            attr.merge!(options)
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
              :collection     => attr[:form_collection]
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
        return if errors === self # TODO: test.

        puts "attempting to merge #{errors.messages} into #{object_id}"

        # TODO: merge into AM.
        errors.messages.each do |field, msgs|
          field = "#{prefix}.#{field}" if prefix

          msgs = [msgs] if Reform.rails3_0? # DISCUSS: fix in #each?

          msgs.each do |msg|
            next if messages[field] and messages[field].include?(msg)
            puts "adding #{field}"
            add(field, msg)
          end # Forms now contains a plain errors hash. the errors for each item are still available in item.errors.
        end
      end
    end

    require "representable/hash/collection"
    require 'active_model'
    class Forms < Array # DISCUSS: this should be a Form subclass.
      def initialize(ary, options)
        super(ary)
        @options = options
      end

      include Form::ValidateMethods

      # TODO: make valid?(errors) the only public method.
      def valid?
       res= validate_cardinality & validate_items
      end

      def errors
        @errors ||= Form::Errors.new(self)
      end

      # this gives us each { to_hash }
      include Representable::Hash::Collection
      items :parse_strategy => :sync, :instance => true

    private
      def validate_items
        inject(true) do |res, form|
          res = validate_for(form, res)
        end
      end

      def validate_cardinality
        return true unless @options[:cardinality]
        # TODO: use AM's cardinality validator here.
        res = size >= @options[:cardinality][:minimum].to_i

        errors.add(:size, "#{@options[:as]} size is 0 but must be #{@options[:cardinality].inspect}") unless res
        res
      end
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
