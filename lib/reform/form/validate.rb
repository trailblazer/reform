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
    # allow an external deserializer.
    block_given? ? yield(params) : deserialize(params)

    super() # run the actual validation on self.
  end

  def deserialize(params)
    params = deserialize!(params)
    deserializer.new(self).from_hash(params)
  end

private
  # Meant to return params processable by the representer. This is the hook for munching date fields, etc.
  def deserialize!(params)
    # NOTE: it is completely up to the form user how they want to deserialize (e.g. using an external JSON-API representer).
      # use the deserializer as an external instance to operate on the Twin API,
      # e.g. adding new items in collections using #<< etc.
    # DISCUSS: using self here will call the form's setters like title= which might be overridden.
    params
  end

  # Default deserializer for hash.
  # This is input-specific, e.g. Hash, JSON, or XML.
  def deserializer # called on top-level, only, for now.
    deserializer = Disposable::Twin::Schema.from(self.class,
      include:          [Representable::Hash::AllowSymbols, Representable::Hash],
      superclass:       Representable::Decorator,
      representer_from: lambda { |inline| inline.representer_class },
      options_from:     :deserializer,
      exclude_options:  [:default, :populator], # Reform must not copy Disposable/Reform-only options that might confuse representable.
    )

    deserializer
  end


  class DeserializeError < RuntimeError
  end
end
