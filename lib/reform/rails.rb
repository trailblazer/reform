require 'reform/form/active_model'
if defined?(ActiveRecord)
  require 'reform/form/active_record'
end

Reform::Form.class_eval do # DISCUSS: i'd prefer having a separate Rails module to be mixed into the Form but this is way more convenient for 99% users.
  include Reform::Form::ActiveModel
  include Reform::Form::ActiveModel::FormBuilderMethods
end