# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Skip
    class AllBlank
      include Uber::Callable

      def call(form, params, options)
        # TODO: hahahahahaha.
        # FIXME: this is a bit ridiculous.
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
    update!(params)

    super() # run the actual validation on self.

  # rescue Representable::DeserializeError
  #   raise DeserializeError.new("[Reform] Deserialize error: You probably called #validate without setting up your nested models. Check https://github.com/apotonick/reform#populating-forms-for-validation on how to use populators.")
  end

  # Some users use this method to pre-populate a form. Not saying this is right, but we'll keep
  # this method here.
  # DISCUSS: this is only called once, on the top-level form.
  def update!(params)
    deserialize!(params)
  end

private
  def deserialize!(params)
    require "disposable/twin/schema"
    require "reform/form/coercion" # DISCUSS: make optional?

    # NOTE: it is completely up to the form user how they want to deserialize (e.g. using an external JSON-API representer).

    deserializer = Disposable::Twin::Schema.from(self.class.representer_class,
        :include    => [Representable::Hash::AllowSymbols, Representable::Hash, Representable::Coercion], # FIXME: how do we get this info?
        :superclass => Representable::Decorator)

    deserializer.representable_attrs.each do |dfn|
      next unless dfn[:_inline] # FIXME: we have to standardize that!

      # FIXME: collides with Schema?
      dfn.merge!(
        deserialize: lambda { |decorator, params, options|
          decorator.represented.validate(params)

          decorator.represented
        }
      )
    end

      deserializer.new(self).
        # extend(Representable::Debug).
        from_hash(params)

      # use the deserializer as an external instance to operate on the Twin API,
      # e.g. adding new items in collections using #<< etc.

    # DISCUSS: using self here will call the form's setters like title= which might be overridden.
  end

  class DeserializeError < RuntimeError
  end
end
