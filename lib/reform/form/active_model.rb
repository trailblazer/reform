module Reform::Form::ActiveModel
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def property(name, options={})
      delegate options[:on], :to => :model
      super
    end
  end
end