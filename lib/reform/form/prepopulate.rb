# prepopulate!(options)
# prepopulator: ->(model, user_options)
module Reform::Form::Prepopulate
  def prepopulate!(options = {})
    prepopulate_local!(options)  # call #prepopulate! on local properties.
    prepopulate_nested!(options) # THEN call #prepopulate! on nested forms.

    self
  end

  private

  def prepopulate_local!(options)
    schema.each do |dfn|
      next unless block = dfn[:prepopulator]
      Declarative::Option(block, instance_exec: true).(self, options)
    end
  end

  def prepopulate_nested!(options)
    schema.each(twin: true) do |dfn|
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form| form.prepopulate!(options) }
    end
  end
end
