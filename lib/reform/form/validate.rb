# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Skip
    class AllBlank
      include Uber::Callable

      def call(form, options)
        # TODO: Schema should provide property names as plain list.
        # ensure param keys are strings.
        params = options[:input].each_with_object({}) { |(k, v), hash|
          hash[k.to_s] = v
        }

        # return false if any property inputs are populated.
        options[:binding][:nested].definitions.each do |definition|
          value = params[definition.name.to_s]
          return false if (!value.nil? && value != '')
        end

        true # skip this property
      end
    end
  end

  def validate(params)
    # allow an external deserializer.
    @input_params = params # we want to store these for access via dry later
    block_given? ? yield(params) : deserialize(params)

    super() # run the actual validation on self.
  end
  attr_reader :input_params # make the raw input params public

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
  def deserializer!(source = self.class, options = {}) # called on top-level, only, for now.
    deserializer = Disposable::Rescheme.from(
      source,
      {
        include:          [Representable::Hash::AllowSymbols, Representable::Hash],
        superclass:       Representable::Decorator,
        definitions_from: ->(inline) { inline.definitions },
        options_from:     :deserializer,
        exclude_options:  %i[default populator] # Reform must not copy Disposable/Reform-only options that might confuse representable.
      }.merge(options)
    )

    deserializer
  end

  def deserializer(*args)
    # DISCUSS: should we simply delegate to class and sort out memoizing there?
    self.class.deserializer_class || self.class.deserializer_class = deserializer!(*args)
  end

  def self.included(includer)
    includer.singleton_class.send :attr_accessor, :deserializer_class
  end
end
