require 'representable/hash'
require 'representable/decorator'

module Reform
  class Representer < Representable::Decorator
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
        find_all { |attr| attr.options[:form] }.
        collect  { |attr| [attr, represented.send(attr.getter)] }. # DISCUSS: can't we do this with the Binding itself?
        each(&block)
    end

    def self.clone # called in inheritable_attr :representer_class.
      Class.new(self) # By subclassing, representable_attrs.clone is called.
    end

  private
    def clone_config!
      # TODO: representable_attrs.clone! which does exactly what's done below.
      attrs = Representable::Config.new
      attrs.inherit(representable_attrs) # since in every use case we modify Config we clone.
      @representable_attrs = attrs
    end

    def self.inline_representer(base_module, name, options, &block)
      attr = representable_attrs[name]
      name = name.to_s.singularize.camelize

      superclass = Form
      superclass = attr.options[:form] if attr && options[:inherit] == true

      Class.new(superclass) do
        instance_exec &block

        @form_name = name

        def self.name # needed by ActiveModel::Validation and I18N.
          @form_name
        end
      end
    end
  end
end
