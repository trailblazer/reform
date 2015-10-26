# Reform's own implementation for uniqueness which does not write to model.
class Reform::Form::UniqueValidator < ActiveModel::EachValidator
  def validate_each(form, attribute, value)
    has_error = false
    model = form.model_for_property(attribute)
    scope = Array(options[:scope])

    if value.is_a?(Array)
      # validate in memory collection
      # thank you: http://stackoverflow.com/questions/2772236/validates-uniqueness-of-in-destroyed-nested-model-rails
      hashes = value.inject({}) do |hash, record|
        key = scope.map { |a| record.send(a).to_s }.join

        # TODO: add support for marked_as_destruction? when a solution for _destroy is found
        if key.blank?
          key = record.object_id
        end

        hash[key] = record unless hash.has_key?(key)

        hash
      end

      has_error = (value.length > hashes.length)
    else
      # search for models with attribute equals to form field value
      query = model.class.where(attribute => value)

      # apply scope if options has been declared
      scope.each do |field|
        # add condition to only check unique value with the same scope
        query = query.where(field => form.send(field))
      end

      # if model persisted, excluded own model from query
      query = query.merge(model.class.where("id <> ?", model.id)) if model.persisted?

      # if any models found, add error on attribute
      has_error = query.any?
    end

    form.errors.add(attribute, :taken) if has_error
  end
end

# FIXME: ActiveModel loads validators via const_get(#{name}Validator). This magic forces us to
# make the new :unique validator available here.
Reform::Form::ActiveModel::Validations::Validator.class_eval do
  UniqueValidator = Reform::Form::UniqueValidator
end