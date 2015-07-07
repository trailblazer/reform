module Reform::Contract::Validate
  def validate
    options = {errors: errors, prefix: []}
    validate!(options)

    @errors.empty?
  end

  def validate!(options)
    validate_nested!(options) # call valid? recursively and collect nested errors.

    # TODO: pass in errors here!
    valid?  # calls AM/Lotus validators. In AM, this writes to the "global" @errors, which, of course, sucks.

    options[:errors].merge!(errors, options[:prefix])
  end

  def errors
    @errors ||= errors_for_validate
  end

private

  # runs form.validate! on all nested forms
  def validate_nested!(options)
    schema.each(twin: true) do |dfn|
      property_options = options.dup

      property_options[:prefix] = options[:prefix].dup # TODO: implement Options#dup.
      property_options[:prefix] << dfn.name

      # recursively call valid? on nested form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form| form.validate!(property_options) }
    end
  end
end