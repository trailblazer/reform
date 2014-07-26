require 'representable/hash'
require 'representable/decorator'

module Reform
  class Representer < Representable::Decorator
    include Representable::Hash::AllowSymbols

    extend Uber::InheritableAttr
    inheritable_attr :options # FIXME: this doesn't need to be inheritable.
    # self.options = {}


    # Invokes #to_hash and/or #from_hash with #options. This provides a hook for other
    # modules to add options for the representational process.
    module WithOptions
      class Options < Hash
        def include!(names)
          self[:include] ||= []
          self[:include] += names
          self
        end

        def exclude!(names)
          self[:exclude] ||= []
          self[:exclude] +=  names
          self
        end
      end

      def options
        Options.new
      end

      def to_hash(*)
        super(options)
      end

      def from_hash(*)
        super(options)
      end
    end

    include Representable::Hash

    # Returns hash of all property names.
    def fields
      representable_attrs.map(&:name)
    end

    def nested_forms(&block)
      clone_config!.
        find_all { |attr| attr[:form] }.
        each(&block)
    end

    def self.for(options)
      clone.tap do |representer|
        representer.options = options
      end
    end

    def self.default_inline_class
      options[:form_class]
    end

    def self.clone # called in inheritable_attr :representer_class.
      Class.new(self) # By subclassing, representable_attrs.clone is called.
    end

  private
    def clone_config!
      # TODO: representable_attrs.clone! which does exactly what's done below.
      attrs = Representable::Config.new
      attrs.inherit!(representable_attrs) # since in every use case we modify Config we clone.
      @representable_attrs = attrs
    end

    def self.build_inline(base, features, name, options, &block)
      name = name.to_s.singularize.camelize

      puts "inline for #{default_inline_class}, #{name}"

      features = options[:features]

      Class.new(default_inline_class) do
        include *features

        instance_exec &block

        @form_name = name

        def self.name # needed by ActiveModel::Validation and I18N.
          @form_name
        end
      end
    end
  end
end