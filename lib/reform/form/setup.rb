class Reform::Form
  module Setup
    def setup_fields
      representer = mapper.new(aliased_model).extend(Setup::Representer)

      create_fields(representer.fields, representer.to_hash)
    end

    def create_fields(field_names, fields)
      Reform::Fields.new(field_names, fields)
    end


    # Mechanics for setting up initial Field values.
    module Representer
      include Reform::Representer::WithOptions
      include EmptyAttributesOptions

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
end