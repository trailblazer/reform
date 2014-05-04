require 'forwardable'
require 'uber/inheritable_attr'

require 'reform/representer'

module Reform
  # Gives you a DSL for defining the object structure and its validations.
  class Validation # DISCUSS: make class?
    extend Forwardable

    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Reform::Representer)

    self.representer_class.class_eval do
      def self.form_class
        Reform::Validation
      end
    end

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


    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations


    attr_accessor :model

    require 'reform/validation/setup'
    include Setup



    attr_writer :errors # only used in top form.
    private :errors=

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

      def merge!(errors, prefix)
        prefixes = prefix.join(".")

        # TODO: merge into AM.
        errors.messages.each do |field, msgs|
          field = (prefix+[field]).join(".").to_sym # TODO: why is that a symbol in Rails?

          msgs = [msgs] if Reform.rails3_0? # DISCUSS: fix in #each?

          msgs.each do |msg|
            next if messages[field] and messages[field].include?(msg)
            add(field, msg)
          end # Forms now contains a plain errors hash. the errors for each item are still available in item.errors.
        end
      end

      def valid? # TODO: test me in unit test.
        blank?
      end
    end # Errors




    module NestedValid
      def to_hash(*)
        nested_forms do |attr|
          # attr.delete(:prepare)
          # attr.delete(:extend)

          attr.merge!(
            :serialize => lambda { |object, args|

              # FIXME: merge with Validate::Writer
              options = args.user_options.dup
              options[:prefix] = options[:prefix].dup # TODO: implement Options#dup.
              options[:prefix] << args.binding.name # FIXME: should be #as.

              # puts "======= user_options: #{args.user_options.inspect}"

              object.valid?(options) # recursively call valid?
            },
          )
        end

        super
      end
    end

    def validate
      options = {:errors => errs = Reform::Validation::Errors.new(self), :prefix => []}

      validate!(options)

      self.errors = errs # if the AM valid? API wouldn't use a "global" variable this would be better.

      errors.valid?
    end
    def validate!(options)
      prefix = options[:prefix]

      # call valid? recursively and collect nested errors.
      mapper.new(self).extend(NestedValid).to_hash(options)

      res = valid?  # this validates on <Fields> using AM::Validations, currently.

      options[:errors].merge!(self.errors, prefix)
    end









  private
    attr_accessor :fields

    def mapper
      self.class.representer_class
    end

    alias_method :aliased_model, :model


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