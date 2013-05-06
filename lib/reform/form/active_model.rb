module Reform::Form::ActiveModel
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def model(*args)
      @model_options = args  # FIXME: make inheritable!

      delegate "persisted?", :to_key, :to_param, :to => args.last[:on]
      alias_method args.first, args.last[:on] # delegate #hit to #song to #model.
    end

    def property(name, options={})
      delegate options[:on], :to => :model
      super
    end

    def model_name
      ActiveModel::Name.new(self, nil, @model_options.first.to_s.camelize)
    end
  end
end