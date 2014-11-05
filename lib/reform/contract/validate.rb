module Reform::Contract::Validate
  def validate
    options = {:errors => errs = Reform::Contract::Errors.new(self), :prefix => []}

    validate!(options)

    self.errors = errs # if the AM valid? API wouldn't use a "global" variable this would be better.

    errors.valid?
  end

  def validate!(options)
    prefix = options[:prefix]

    # call valid? recursively and collect nested errors.
    valid_representer.new(fields).to_hash(options) # TODO: only include nested forms here.

    valid?  # this validates on <Fields> using AM::Validations, currently.

    options[:errors].merge!(self.errors, prefix)
  end

private

  # runs form.validate! on all nested forms
  def valid_representer
    self.class.representer(:valid) do |dfn|
      dfn.merge!(
        :serialize => lambda { |form, args|
          options = args.user_options.dup
          options[:prefix] = options[:prefix].dup # TODO: implement Options#dup.
          options[:prefix] << args.binding.name # FIXME: should be #as.

          form.validate!(options) # recursively call valid? on nested form.
        }
      )
    end
  end
end