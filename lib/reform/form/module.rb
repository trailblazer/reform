# Include this in every module that gets further included.
module Reform::Form::Module
  def self.included(base)
    base.extend ClassMethods

    base.extend Declarative::Heritage::DSL      # ::heritage
    base.extend Declarative::Heritage::Included # ::included
  end

  module ClassMethods
    def method_missing(method, *args, &block)
      heritage.record(method, *args, &block)
    end
  end
end