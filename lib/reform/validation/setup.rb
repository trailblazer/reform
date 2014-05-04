
module Reform
  class Validation
    module Setup
      def initialize(model)
        @model  = model # we need this for #save.
        @fields = setup_fields  # delegate all methods to Fields instance.
      end

      def setup_fields
        representer = mapper.new(aliased_model).extend(Setup::Representer)

        create_fields(representer.fields, representer.to_hash)
      end

      def create_fields(field_names, fields)
        Fields.new(field_names, fields)
      end


      # Mechanics for setting up initial Field values.
      module Representer
        require 'reform/form/virtual_attributes' # FIXME: that shouldn't be here.

        include Reform::Representer::WithOptions
        include Reform::Form::EmptyAttributesOptions # FIXME: that shouldn't be here.

        def to_hash(*)
          nested_forms do |attr|
            attr.merge!(
              :representable => false, # don't call #to_hash.
              :prepare       => lambda do |model, args|
                args.binding[:form].new(model)
              end
            )
          end

          super # TODO: allow something like super(:exclude => empty_fields)
        end
      end # Representer
    end
  end # Validation
end