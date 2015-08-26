# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Skip
    class AllBlank
      include Uber::Callable

      def call(form, params, options)
        # TODO: Schema should provide property names as plain list.
        properties = options.binding[:twin].representer_class.representable_attrs[:definitions].keys

        properties.each { |name| params[name].present? and return false }
        true # skip
      end
    end
  end


  # 1. Populate the form object graph so that each incoming object has a representative form object.
  # 2. Deserialize. This is wrong and should be done in 1.
  # 3. Validate the form object graph.
  def validate(params)
    deprecate_update!(params)

    # allow an external deserializer.
    block_given? ? yield(params) : deserialize(params)

    super() # run the actual validation on self.
  # rescue Representable::DeserializeError
  #   raise DeserializeError.new("[Reform] Deserialize error: You probably called #validate without setting up your nested models. Check https://github.com/apotonick/reform#populating-forms-for-validation on how to use populators.")
  end

  # Meant to return params processable by the representer. This is the hook for munching date fields, etc.
  def deserialize!(params)
    # NOTE: it is completely up to the form user how they want to deserialize (e.g. using an external JSON-API representer).
      # use the deserializer as an external instance to operate on the Twin API,
      # e.g. adding new items in collections using #<< etc.
    # DISCUSS: using self here will call the form's setters like title= which might be overridden.
    params
  end


private
  # Some users use this method to pre-populate a form. Not saying this is right, but we'll keep
  # this method here.
  # DISCUSS: this is only called once, on the top-level form.
  def deprecate_update!(params)
    return unless self.class.instance_methods(false).include?(:update!)
    warn "[Reform] Form#update! is deprecated and will be removed in Reform 2.1. Please use #prepopulate!"
    update!(params)
  end

  def deserialize(params)
    params = deserialize!(params)

    deserializer.new(self).from_hash(params)
  end

  # Default deserializer for hash.
  # This is input-specific, e.g. Hash, JSON, or XML.
  def deserializer # called on top-level, only, for now.
    deserializer = Disposable::Twin::Schema.from(self.class,
      include:          [Representable::Hash::AllowSymbols, Representable::Hash],
      superclass:       Representable::Decorator,
      representer_from: lambda { |inline| inline.representer_class },
      options_from:     :deserializer,
      exclude_options:  [:default], # Reform must not copy Disposable/Reform-only options that might confuse representable.
    ) do |dfn|
      # next unless dfn[:twin]
      dfn.merge!(
        deserialize: lambda { |decorator, params, options|
          params = decorator.represented.deserialize!(params) # let them set up params. # FIXME: we could also get a new deserializer here.

          decorator.from_hash(params) # options.binding.deserialize_method.inspect
        }
      ) if dfn[:twin]
    end

    deserializer
  end


  class DeserializeError < RuntimeError
  end
end
