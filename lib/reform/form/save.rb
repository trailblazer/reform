class Reform::Form
  module Save
    module OnNested
      def to_hash(*)
        # process output from InputRepresenter {title: "Mint Car", hit: <Form>}
        # and just call sync! on nested forms.
        nested_forms do |attr|
          attr.merge!(
            :instance  => lambda { |fragment, *| fragment },
            :serialize => lambda { |object, args| object.save! unless args.binding[:save] === false },
          )
        end

        super
      end
    end

    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      sync_models # recursion
      save!
    end

    def save!
      save_model
      mapper.new(self).extend(OnNested).to_hash # save! on all nested forms.
    end

    def save_model
      model.save # TODO: implement nested (that should really be done by Twin/AR).
    end
  end
end