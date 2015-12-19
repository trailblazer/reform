require "veto"

module Reform::Form::Veto
  class Errors < Veto::Errors
    def merge!(errors, prefix)
      errors.each do |name, err|
        field = (prefix+[name]).join(".")
        add(field, *err)
      end
    end

    def messages
      self
    end
  end


  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods
    def validates(*args)
        checker.validates(*args)
      end

      def validate(*args)
        checker.validate(*args)
      end

      def checker
        @checker ||= build_checker
      end

      private

      def build_checker(children=[])
        Veto::Checker.from_children(children)
      end
  end

  def build_errors
    Errors.new
  end

  private

  def valid?
    errors.clear
    self.class.checker.call(Veto::CheckContextObject.new(self, self, errors))
    errors.empty?
  end
end
