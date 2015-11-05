# === Unique Validation
# Reform's own implementation for uniqueness which does not write to model
#
# == Usage
# Pass a true boolean value to validate a field against all values available in
# the database:
# validates :title, unique: true
#
# == Options
# = Scope
# A scope can be use to filter the records that need to be compare with the
# current value to validate. A scope array can have one to many fields define.
#
# A scope can be define the following ways:
# validates :title, unique: { scope: :album_id }
# validates :title, unique: { scope: [:album_id] }
# validates :title, unique: { scope: [:album_id, ...] }
#
# All fields included in a scope must be declared as a property like this:
# property :album_id
# validates :title, unique: { scope: :album_id }
#
# Just remove write access to the property if the field must not be change:
# property :album_id, writeable: false
# validates :title, unique: { scope: :album_id }
#
# This use case is useful if album_id is set to a Song this way:
# song = album.songs.new
# album_id is automatically set and can't be change by the operation

class Reform::Form::UniqueValidator < ActiveModel::EachValidator
  def validate_each(form, attribute, value)
    model = form.model_for_property(attribute)

    # search for models with attribute equals to form field value
    query = model.class.where(attribute => value)

    # apply scope if options has been declared
    Array(options[:scope]).each do |field|
      # add condition to only check unique value with the same scope
      query = query.where(field => form.send(field))
    end

    # if model persisted, query may return 0 or 1 rows, else 0
    allow_count = model.persisted? ? 1 : 0
    form.errors.add(attribute, :taken) if query.count > allow_count
  end
end

# FIXME: ActiveModel loads validators via const_get(#{name}Validator). This magic forces us to
# make the new :unique validator available here.
Reform::Form::ActiveModel::Validations::Validator.class_eval do
  UniqueValidator = Reform::Form::UniqueValidator
end
