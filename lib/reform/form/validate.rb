# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Skip
    class AllBlank
      include Uber::Callable

      def call(form, options)
        params = options[:input]
        # TODO: Schema should provide property names as plain list.
        properties = options[:binding][:nested].definitions.collect { |dfn| dfn[:name] }

        properties.each { |name| (!params[name].nil? && params[name] != "") and return false }
        true # skip
      end
    end
  end


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
  def deserializer(source=self.class, options={}) # called on top-level, only, for now.
    deserializer = Disposable::Rescheme.from(source,
      {
        include:          [Representable::Hash::AllowSymbols, Representable::Hash],
        superclass:       Representable::Decorator,
        definitions_from: lambda { |inline| inline.definitions },
        options_from:     :deserializer,
        exclude_options:  [:default, :populator] # Reform must not copy Disposable/Reform-only options that might confuse representable.
      }.merge(options)
    )

    deserializer
  end


  class DeserializeError < RuntimeError
  end
end
