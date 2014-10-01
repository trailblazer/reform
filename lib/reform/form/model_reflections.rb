# ModelReflections will be the interface between the form object and form builders like simple_form.
#
# This module is meant to collect all dependencies simple_form needs in addition to the ActiveModel ones.
# Goal is to collect all methods and define a reflection API so simple_form works with all ORMs and Reform
# doesn't have to "guess" what simple_form and other form helpers need.
module Reform::Form::ModelReflections
  def self.included(base)
    base.register_feature self # makes it work in nested forms.
  end

  # Delegate column for attribute to the model to support simple_form's
  # attribute type interrogation.
  def column_for_attribute(name)
    model_for_property(name).column_for_attribute(name)
  end
end
