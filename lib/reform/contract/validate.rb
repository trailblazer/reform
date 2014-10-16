module Reform::Contract::Validate
  module NestedValid
    def to_hash(*)
      nested_forms do |attr|
        attr.merge!(
          :serialize => lambda { |object, args|

            # FIXME: merge with Validate::Writer
            options = args.user_options.dup
            options[:prefix] = options[:prefix].dup # TODO: implement Options#dup.
            options[:prefix] << args.binding.name # FIXME: should be #as.

            object.validate!(options) # recursively call valid?
          },
        )
      end

      super
    end
  end

  def validate
    options = {:errors => errs = Reform::Contract::Errors.new(self), :prefix => []}

    validate!(options)

    self.errors = errs # if the AM valid? API wouldn't use a "global" variable this would be better.

    errors.valid?
  end
  def validate!(options)
    prefix = options[:prefix]

    # call valid? recursively and collect nested errors.
    mapper.new(fields).extend(NestedValid).to_hash(options) # TODO: only include nested forms here.

    valid?  # this validates on <Fields> using AM::Validations, currently.

    options[:errors].merge!(self.errors, prefix)
  end

end