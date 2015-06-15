class Reform::Form::UniqueValidator < ActiveModel::EachValidator
  def validate_each(form, attribute, value)
    if form.model.persisted?
      if form.model.class.where("#{attribute} = ? AND id <> ?", value, form.model.id).size > 0
        form.errors.add attribute, "#{attribute} must be unique."
      end
    else
      if form.model.class.where("#{attribute} = ?", value).size > 0
        form.errors.add attribute, "#{attribute} must be unique."
      end
    end
  end
end

