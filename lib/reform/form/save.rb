class Reform::Form
  module Save
    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      sync_models
      save_models
    end

    def save_models
      model.save # TODO: implement nested (that should really be done by Twin/AR).
    end
  end
end