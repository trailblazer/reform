# Include this in every module that gets further included.
module Reform::Form::Module
  def self.included(base)
    base.extend ClassMethods

    base.extend Declarative::DSL # FIXME: should be H:DSL
    base.extend Declarative::Inheritance # FIXME: should be H:ModuleInclusion
  end

  module ClassMethods
    def method_missing(method, *args, &block)
      heritage << { method: method, args: args, block: block }
    end
  end
end