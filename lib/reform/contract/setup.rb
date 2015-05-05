module Reform
  class Contract
    module Setup
      def initialize(model)
        @model  = model # we need this for #save.
        setup_fields!   # copy scalars to the contract instance and wrap nested objects into their contract.
      end

      # Setup#to_hash will create a nested hash of property values from the model.
      # Nested properties will be recursively wrapped in a form instance.
      def setup_representer
        self.class.representer(:setup, :superclass => self.class.object_representer_class) do |dfn| # only nested forms.
          dfn.merge!(
            :representable => false, # don't call #to_hash, only prepare.
            :instance      => lambda { |model, *args| args.last.binding[:form].new(model) } # wrap nested properties in form.
          )
        end
      end

      def setup_fields!
        @fields = Fields.new(mapper.fields)

        representer = setup_representer.new(fields)
        options     = setup_options(Reform::Representer::Options[]) # handles :empty.

        # populate the internal @fields set with data from the model.
        representer.from_object(aliased_model, options) # FIXME: options!
      end

      module SetupOptions
        def setup_options(options)
          options
        end
      end
      include SetupOptions


      module Readable
        def setup_options(options)
          empty_fields = mapper.representable_attrs.find_all { |d| d[:_readable] == false }.collect  { |d| d.name.to_sym }

          options.exclude!(empty_fields)
        end
      end
      include Readable
    end
  end # Setup
end