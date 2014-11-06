module Reform::Form::Save
  # Returns the result of that save invocation on the model.
  def save(options={}, &block)
    # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
    return yield to_nested_hash if block_given?

    sync_models # recursion
    save!(options)
  end

  def save!(options={}) # FIXME.
    result = save_model

    save_representer.new(fields).to_hash # save! on all nested forms.

    dynamic_save!(options)

    result
  end

  def save_model
    model.save # TODO: implement nested (that should really be done by Twin/AR).
  end


  require "active_support/hash_with_indifferent_access" # DISCUSS: replace?
  def to_nested_hash(*)
    ActiveSupport::HashWithIndifferentAccess.new(nested_hash_representer.new(fields).to_hash)
  end
  alias_method :to_hash, :to_nested_hash
  # NOTE: it is not recommended using #to_hash and #to_nested_hash in your code, consider them private.

private
  def save_representer
    self.class.representer(:save) do |dfn|
      dfn.merge!(
        :instance  => lambda { |form, *| form },
        :serialize => lambda { |form, args| form.save! unless args.binding[:save] === false }
      )
    end
  end

  def nested_hash_representer
    self.class.representer(:nested_hash, :all => true) do |dfn|
      dfn.merge!(:serialize => lambda { |form, args| form.to_nested_hash }) if dfn[:form]

      dfn.merge!(:as => dfn[:private_name] || dfn.name)
    end
  end

  def dynamic_save!(options)
    names = options.keys & changed.keys.map(&:to_sym)
    return if names.size == 0

    dynamic_save_representer.new(fields).to_hash(options.merge(:include => names))
  end

  def dynamic_save_representer
    self.class.representer(:dynamic_save, :all => true) do |dfn|
      dfn.merge!(
        :serialize     => lambda { |object, options| options.user_options[options.binding.name.to_sym].call(object, options) },
        :representable => true
      )
    end
  end
end
