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
    result = form.to_result
    result.messages.collect { |k, v| hash[[*prefix, k].join(".").to_sym] = v }

    form.schema.each(twin: true) do |dfn|
      Disposable::Twin::PropertyProcessor.new(dfn, form).() do |frm, i|
        form_obj = i ? form.send(dfn[:name])[i] : form.send(dfn[:name])
        DottedErrors.(form_obj, [*prefix, dfn[:name]], hash)
      end
    end
  end

  def messages(*args)
    @dotted_errors
  end

  def full_messages
	  @dotted_errors.collect { |path, errors|
		  human_field = path.to_s.gsub(/([\.\_])+/, " ").gsub(/(\b\w)+/) { |s| s.capitalize }
			 errors.collect { |message| "#{human_field} #{message}" }
		}.flatten
  end

  def [](name)
  	@dotted_errors[name] || []
  end

  def size
    messages.size
  end

  # needed for rails form helpers
  def empty?
    messages.empty?
  end

  # we need to delegate adding error to result because every time we call form.errors
  # a new instance of this class is created so we need to update the @results array
  # to be able to add custom errors here.
  # This method will actually work only AFTER a validate call has been made
  def add(key, error_test)
    @result.add_error(key, error_test)
  end
end

# Ensure that we can return Active Record compliant full messages when using dry
# we only want unique messages in our array
#
# @full_errors.add()
