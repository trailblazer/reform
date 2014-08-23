module Reform::Form::Save
  module RecursiveSave
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

  # Returns the result of that save invocation on the model.
  def save(&block)
    # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
    return deprecate_first_save_block_arg(&block) if block_given?

    sync_models # recursion
    save!
  end

  def save!
    result = save_model
    mapper.new(fields).extend(RecursiveSave).to_hash # save! on all nested forms.  # TODO: only include nested forms here.
    result
  end

  def save_model
    model.save # TODO: implement nested (that should really be done by Twin/AR).
  end


  module NestedHash
    def to_hash(*)
      # Transform form data into a nested hash for #save.
      nested_forms do |attr|
        attr.merge!(
          :serialize => lambda { |object, args| object.to_nested_hash }
        )
      end

      representable_attrs.each do |attr|
        attr.merge!(:as => attr[:private_name] || attr.name)
      end

      super
    end
  end


  require "active_support/hash_with_indifferent_access" # DISCUSS: replace?
  def to_nested_hash(*)
    map = mapper.new(fields).extend(NestedHash)

    ActiveSupport::HashWithIndifferentAccess.new(map.to_hash)
  end
  alias_method :to_hash, :to_nested_hash
  # NOTE: it is not recommended using #to_hash and #to_nested_hash in your code, consider
  # them private.

private
  def deprecate_first_save_block_arg(&block)
    if block.arity == 2
      warn "[Reform] Deprecation Warning: The first block argument in `save { |form, hash| .. }` is deprecated and its new signature is `save { |hash| .. }`. If you need the form instance, use it in the block. Have a good day."
      return yield(self, to_nested_hash)
    end

    yield to_nested_hash # new behaviour.
  end
end
