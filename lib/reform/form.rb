require 'ostruct'

require 'reform/validation'
require 'reform/composition'

module Reform
  class Form < Validation
    # self.representer_class.form_class = self
    self.representer_class.class_eval do
      def self.form_class
        Reform::Form
      end
    end

    def aliased_model
      # TODO: cache the Expose.from class!
      Reform::Expose.from(self.class.representer_class).new(:model => model)
    end

    require "reform/form/virtual_attributes"

    require 'reform/form/validate'
    include Validate
    require 'reform/form/sync'
    include Sync
    require 'reform/form/save'
    include Save

    require 'reform/form/multi_parameter_attributes'
    include MultiParameterAttributes # TODO: make features dynamic.
  end
end
