class Reform::Form::UniqueValidator < ActiveModel::EachValidator
  def validate_each(form, attribute, value)
    if form.model.class.where("#{attribute} = ?", value).size > 0
      form.errors.add attribute, "#{attribute} must be unique."
    end
  end
end