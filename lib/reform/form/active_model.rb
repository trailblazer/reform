module Reform::Form::ActiveModel
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def model(main_model, options={})
      @model_options    = [main_model, options]  # FIXME: make inheritable!
      composition_model = options[:on] || main_model

      delegate composition_model => :model # #song => model.song
      delegate [:persisted?, :to_key, :to_param, :to_model] => composition_model  # #to_key => song.to_key

      alias_method main_model, composition_model # #hit => model.song.
    end

    def property(name, options={})
      delegate options[:on] => :model
      super
    end

    def model_name
      name = @model_options.first.to_s.camelize

      return ::ActiveModel::Name.new(OpenStruct.new(:name => name)) if ::ActiveModel::VERSION::MAJOR == 3 and ::ActiveModel::VERSION::MINOR == 0
      ::ActiveModel::Name.new(self, nil, name)
    end
  end
end
