module Reform::Contract::Validate
  def validate
    validate!(errors, [])

    errors.empty?
  end

  def validate!(errors, prefix)
    validate_nested!(nested_errors = errors_for_validate, prefix) # call valid? recursively and collect nested errors.

    valid?  # calls AM/Lotus validators.

    errors.merge!(self.errors, prefix) # local errors.
    errors.merge!(nested_errors, []) #
    puts "---------> #{nested_errors.send(:errors).inspect}"
  end

  def errors
    @errors ||= errors_for_validate
  end

private

  # runs form.validate! on all nested forms
  def validate_nested!(errors, prefix)
    schema.each(twin: true) do |dfn|
      prefixes = prefix.dup # TODO: implement Options#dup.
      prefixes << dfn.name

      # recursively call valid? on nested form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form| form.validate!(errors, prefixes) }
    end
  end
end