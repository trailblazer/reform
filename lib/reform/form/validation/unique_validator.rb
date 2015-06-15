class Reform::Form::UniqueValidator < ActiveModel::EachValidator
  def validate_each(form, attribute, value)
    # search for models with attribute equals to form field value
    query = form.model.class.where(attribute => value)

    # if model persisted, excluded own model from query
    query = query.merge(form.model.class.where("id <> ?", form.model.id)) if form.model.persisted?

    # if any models found, add error on attribute
    form.errors.add(attribute, "#{attribute} must be unique.") if query.any?
  end
end

