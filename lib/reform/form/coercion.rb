require 'representable/decorator/coercion'

class Reform::Form
  module Coercion
    def self.included(base)
      base.extend(ClassMethods)
      base.features << self
    end

    module ClassMethods
      def representer_class
        super.class_eval do
          include Representable::Decorator::Coercion unless self < Representable::Decorator::Coercion # DISCUSS: include it once. why do we have to check this?
          self
        end
      end
    end
  end
end
