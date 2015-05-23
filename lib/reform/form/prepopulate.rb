# prepopulate!(options)
# prepopulator: ->(model, user_options)
module Reform::Form::Prepopulate
  def prepopulate!(options={})
    prepopulator_representer.new(self).to_object(options) # call #prepopulate! on local properties.

    recursive_prepopulator_representer.new(self).to_object(options) # THEN call #prepopulate! on nested forms.
    self
  end

private
  def prepopulator_representer
    self.class.representer(:prepopulator, all: true, superclass: self.class.object_representer_class) do |dfn|
      next unless block = dfn[:prepopulator]

        dfn.merge!(
          writer: Prepopulator.new(block),
        )
    end
  end

  def recursive_prepopulator_representer
    self.class.representer(:recursive_prepopulator_representer, superclass: self.class.object_representer_class) do |dfn|
      dfn.merge!(
        serialize: lambda { |object, options| model = object.prepopulate!(options.user_options) },
        representable: true
      )
    end
  end

  # This Callable wraps and invokes the :prepopulator lambda/option and is called in #prepopulate!.
  class Prepopulator < Reform::Form::Populator
  private
    def call!(form, fragment, model, options)
      return @value.evaluate(form, options)

      # FIXME: use U:::Value.
      form.instance_exec(options, &@user_proc) # pass user_options, we got access to everything.
    end

    def handle_fail(twin, options)
      # TODO: implement,
      # e.g. collections may return [] instead of one twin.
    end
  end
end