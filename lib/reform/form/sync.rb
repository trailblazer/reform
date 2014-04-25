class Reform::Form
  # #sync!
  #   1. assign scalars to model (respecting virtual, excluded attributes)
  #   2. call sync! on nested
  module Sync
    # Mechanics for writing input to model.
      # Writes input to model.
      module Writer
        def from_hash(*)
          # process output from InputRepresenter {title: "Mint Car", hit: <Form>}
          # and just call sync! on nested forms.
          nested_forms do |attr|
            attr.merge!(
              :instance     => lambda { |fragment, *| fragment },
              :deserialize => lambda { |object, *| object.sync! },
            )
          end

          super
        end
      end

      # Transforms form input into what actually gets written to model.
      # output: {title: "Mint Car", hit: <Form>}
      module InputRepresenter
        include Reform::Representer::WithOptions
        # TODO: make dynamic.
        include EmptyAttributesOptions
        include ReadonlyAttributesOptions

        def to_hash(*)
          nested_forms do |attr|
            attr.merge!(
              :representable  => false,
              :prepare        => lambda { |obj, *| obj }
            )

          end

          super
        end
      end
    end

    ### TODO: add ToHash with :prepare => lambda { |form, args| form },

    def sync_to_models # TODO: rename to #sync_models
      sync!
    end

    def sync!
      input_representer = mapper.new(self).extend(InputRepresenter)

      input = input_representer.to_hash

      mapper.new(model).extend(Writer).from_hash(input)
    end
end