# Reform's own implementation for uniqueness which does not write to model.
class Reform::Form::UniqueValidator < ActiveModel::EachValidator
  def validate_each(form, attribute, value)
    model = form.model_for_property(attribute)

    # search for models with attribute equals to form field value
    query = model.class.where(attribute => value)

    # if model persisted, excluded own model from query
    query = query.merge(model.class.where("id <> ?", model.id)) if model.persisted?

    # if any models found, add error on attribute
    form.errors.add(attribute, "#{attribute} must be unique.") if query.any?
  end
end

# FIXME: ActiveModel loads validators via const_get(#{name}Validator). This magic forces us to
# make the new :unique validator available here.
Reform::Form::ActiveModel::Validations::Validator.class_eval do
  UniqueValidator = Reform::Form::UniqueValidator
end