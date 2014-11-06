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
  def save(options={}, &block)
    # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
    return yield to_nested_hash if block_given?

    sync_models # recursion
    save!(options)
  end

  def save!(options={}) # FIXME.
    result = save_model
    save_representer.new(fields).to_hash # save! on all nested forms.  # TODO: only include nested forms here.

    names = options.keys & changed.keys.map(&:to_sym)
    if names.size > 0
      representer = save_dynamic_representer.new(fields) # should be done once, on class instance level.

      # puts "$$$$$$$$$ #{names.inspect}"
      representer.to_hash(options.merge :include => names)
    end

    result
  end

  def save_model
    model.save # TODO: implement nested (that should really be done by Twin/AR).
  end

  def save_dynamic_representer
    # puts mapper.superclass.superclass.inspect
    Class.new(mapper).apply do |dfn|
      dfn.merge!(
        :serialize => lambda { |object, options|
          puts "$$ #{options.user_options.inspect}"
          options.user_options[options.binding.name.to_sym].call(object, options) },
        :representable => true
      )
    end
  end


  require "active_support/hash_with_indifferent_access" # DISCUSS: replace?
  def to_nested_hash(*)
    ActiveSupport::HashWithIndifferentAccess.new(nested_hash_representer.new(fields).to_hash)
  end
  alias_method :to_hash, :to_nested_hash
  # NOTE: it is not recommended using #to_hash and #to_nested_hash in your code, consider
  # them private.

private
  def save_representer
    self.class.representer(:save) do |dfn|
      dfn.merge!(
          :instance  => lambda { |form, *| form },
          :serialize => lambda { |form, args| form.save! unless args.binding[:save] === false },
        )
    end
  end

  def nested_hash_representer
    self.class.representer(:nested_hash, :all => true) do |dfn|
      dfn.merge!(:serialize => lambda { |form, args| form.to_nested_hash }) if dfn[:form]

      dfn.merge!(:as => dfn[:private_name] || dfn.name)
    end
  end
end
