module Reform::Contract::Validate
  def validate
    options = {:errors => errs = Reform::Contract::Errors.new(self), :prefix => []}

    validate!(options)

    self.errors = errs # if the AM valid? API wouldn't use a "global" variable this would be better.

    errors.valid?
  end

  def validate!(options)
    prefix = options[:prefix]

    validate_nested!(options) # call valid? recursively and collect nested errors.
puts "calling valid?"
    valid?  # this validates on <Fields> using AM::Validations, currently.

    options[:errors].merge!(self.errors, prefix)
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