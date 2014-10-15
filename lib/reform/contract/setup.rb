module Reform
  class Contract
    module Setup
      def initialize(model)
        @model  = model # we need this for #save.
        @fields = setup_fields  # delegate all methods to Fields instance.
      end

      def setup_fields
        representer = mapper.new(aliased_model).extend(Setup::Representer)
        options     = setup_options(Reform::Representer::Options[]) # handles :empty.

        create_fields(representer.fields, representer.to_hash(options))
      end

      # DISCUSS: setting up the Validation (populating with values) will soon be handled with Disposable::Twin logic.
      def create_fields(field_names, fields)
        Fields.new(field_names, fields)
      end

      module SetupOptions
        def setup_options(options)
          options
        end
      end
      include SetupOptions


      # Mechanics for setting up initial Field values.
      module Representer
        def to_hash(*)
          nested_forms do |attr|
            attr.merge!(
              :representable => false, # don't call #to_hash.
              :prepare       => lambda do |model, args|
                args.binding[:form].new(model)
              end
            )
          end

          super
        end
      end # Representer


      module Empty
        def setup_options(options)
          empty_fields = mapper.representable_attrs.find_all { |d| d[:empty] }.collect  { |d| d.name.to_sym }

          puts "excluuuuuding #{empty_fields.inspect}"
          options.exclude!(empty_fields)
        end
      end
      include Empty
    end
  end # Setup
end