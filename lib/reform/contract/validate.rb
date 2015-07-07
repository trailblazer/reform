module Reform::Contract::Validate
  def validate
    validate!(errs=errors_for_validate, [])

    @errors = errs
    errors.empty?
  end

  def validate!(errors, prefix)
    validate_nested!(nested_errors = errors_for_validate, prefix) # call valid? recursively and collect nested errors.

    valid?  # calls AM/Lotus validators and invokes self.errors=.

    errors.merge!(self.errors, prefix) # local errors.
    errors.merge!(nested_errors, []) #
  end

  def errors
    @errors ||= errors_for_validate
  end

private

  # runs form.validate! on all nested forms
  def validate_nested!(errors, prefixes)
    schema.each(twin: true) do |dfn|
      # recursively call valid? on nested form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form| form.validate!(errors, prefixes+[dfn.name]) }
    end
  end
end