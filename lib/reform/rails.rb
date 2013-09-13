require 'reform/form/active_model'
if defined?(ActiveRecord)
  require 'reform/form/active_record'
end

class Reform::Form
  module Rails
    extend ActiveSupport::Concern

    included do
      include ActiveModel::FormBuilderMethods # DISCUSS: name scheme will change soon.
    end
  end
end