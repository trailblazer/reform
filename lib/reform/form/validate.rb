# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Skip
    class AllBlank
      include Uber::Callable

      def call(form, params, options)
        # TODO: hahahahahaha.
        properties = options.binding.representer_module.representer_class.representable_attrs[:definitions].keys

        properties.each { |name| params[name].present? and return false }
        true # skip
      end
    end
  end


  class Changed
    def call(fragment, params, options)
      # options is a Representable::Options object holding all the stakeholders. this is here becaues of pass_options: true.
      form = options.represented
      name = options.binding.name

      form.changed[name] = form.send(name) != fragment

      fragment
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
  def update!(params)
    deserialize!(params)
  end

private
  def deserialize!(params)
    require "disposable/twin/schema"
    require "reform/form/coercion" # DISCUSS: make optional?

    deserializer = Disposable::Twin::Schema.from(self.class.twin_representer_class,
        :include    => [Representable::Hash::AllowSymbols, Representable::Hash, Representable::Coercion], # FIXME: how do we get this info?
        :superclass => Representable::Decorator)

      deserializer.new(self).
        # extend(Representable::Debug).
        from_hash(params)

      return
      # use the deserializer as an external instance to operate on the Twin API,
      # e.g. adding new items in collections using #<< etc.



    # using self here will call the form's setters like title= which might be overridden.
    # from_hash(params, parent_form: self)
    # Go through all nested forms and call form.update!(hash).
    populate_representer.new(self).send(deserialize_method, params, :parent_form => self)
  end

  def deserialize_method
    :from_hash
  end

  # IDEA: what if Populate was a Decorator that simply knows how to setup the Form object graph, nothing more? That would decouple
  # the population from the validation (good and bad as less customizable).

  # Don't get scared by this method. All this does is create a new representer class for this form.
  # It then configures each property so the population of the form can happen in #validate.
  # A lot of this code is simply renaming from Reform's API to representable's. # FIXME: unify that?
  def populate_representer
    self.class.representer(:populate, :all => true) do |dfn|
      if dfn[:form]
        dfn.merge!(
          # set parse_strategy: sync> # DISCUSS: that kills the :setter directive, which usually sucks. at least document this in :populator.

          # :getter grabs nested forms directly from fields bypassing the reader method which could possibly be overridden for presentation.
          :getter      => lambda { |options| fields.send(options.binding.name) },
          :deserialize => lambda { |object, params, args| object.update!(params) },
        )

        # TODO: :populator now is just an alias for :instance. handle in ::property.
      end


      dfn.merge!(:parse_filter => Representable::Coercion::Coercer.new(dfn[:coercion_type])) if dfn[:coercion_type]

      dfn.merge!(:skip_if => Skip::AllBlank.new) if dfn[:skip_if] == :all_blank
      dfn.merge!(:skip_parse => dfn[:skip_if]) if dfn[:skip_if]

      dfn.merge!(:parse_filter => Changed.new) unless dfn[:form] # TODO: make changed? work for nested forms.
    end
  end

  class DeserializeError < RuntimeError
  end
end
