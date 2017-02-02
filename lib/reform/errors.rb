# Provides the old API for Rails and friends.
# Note that this might become an optional "deprecation" gem in Reform 3.
class Reform::Contract::Result::Errors
  def initialize(result, form)
    @result        = result # DISCUSS: we don't use this ATM?
    @form          = form
    @dotted_errors = {} # Reform does not endorse this style of error msgs.

    DottedErrors.(@form, [], @dotted_errors)
  end

  # PROTOTYPING. THIS WILL GO TO A SEPARATE GEM IN REFORM 2.4/3.0.
  DottedErrors = ->(form, prefix, hash) do
    bla=form.to_result
    return unless bla # FIXME.
    bla.errors.collect { |k,v| hash[ [*prefix, k].join(".").to_sym] = v }

    form.schema.each(twin: true) { |dfn|
      Disposable::Twin::PropertyProcessor.new(dfn, form).() do |frm, i|
        DottedErrors.(form.send(dfn[:name])[i], [*prefix, dfn[:name], i], hash) and next if i
        DottedErrors.(form.send(dfn[:name]), [*prefix, dfn[:name]], hash)
      end
    }
  end

  def messages(*args)
    # warn "[Reform] form.errors.messages will be deprecated in Reform 2.4."
    # @result.messages(*args)
    @dotted_errors
  end

  def [](name)
  	@dotted_errors[name]
  end

  def size
    messages.size
  end
end
