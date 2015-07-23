# Rails acceptance validation that does not write to model.
class Reform::Form::AcceptValidator < ActiveModel::EachValidator
  def initialize(options)
    super({ accepted: ["1", true] }.merge!(options))
  end

  def validate_each(form, attribute, value)
    unless accepted_option?(value)
      form.errors.add(attribute, :accepted, options)
    end
  end

  private

  def accepted_option?(value)
    Array(options[:accepted]).include?(value)
  end
end

Reform::Form::ActiveModel::Validations::Validator.class_eval do
  AcceptValidator = Reform::Form::AcceptValidator
end
