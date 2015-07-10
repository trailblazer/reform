module Reform::Form::ORM
  def model_for_property(name)
    return model unless is_a?(Reform::Form::Composition) # i am too lazy for proper inheritance. there should be a ActiveRecord::Composition that handles this.

    model_name = options_for(name)[:on]
    model[model_name]
  end

  module UniquenessValidator
    # when calling validates it should create the Vali instance already and set @klass there! # TODO: fix this in AM.
    def validate(form)
      property = attributes.first

      # here is the thing: why does AM::UniquenessValidator require a filled-out record to work properly? also, why do we need to set
      # the class? it would be way easier to pass #validate a hash of attributes and get back an errors hash.
      # the class for the finder could either be infered from the record or set in the validator instance itself in the call to ::validates.
      record = form.model_for_property(property)
      record.send("#{property}=", form.send(property))

      @klass = record.class # this is usually done in the super-sucky #setup method.
      super(record).tap do |res|
        form.errors.add(property, record.errors.first.last) if record.errors.present?
      end
    end
  end
end
