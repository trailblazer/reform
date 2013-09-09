module Reform::Form::ActiveModel
  module FormBuilderMethods # TODO: rename to FormBuilderCompat.
    def self.included(base)
      base.class_eval do
        # delegating id is required from FB when rendering a nested persisted object.
        delegate [:persisted?, :to_key, :to_param, :id] => :model
        extend ClassMethods # ::model_name

        def to_model # this is called somewhere in FormBuilder.
          self
        end
      end
    end

    module ClassMethods
      def model(main_model, options={})
        @model_options = [main_model, options]  # FIXME: make inheritable!
      end

      def property(name, options={})
        add_nested_attribute_compat(name) if block_given? # TODO: fix that in Rails FB#1832 work.
        super
      end

      def model_name # TODO: clean up.
        if @model_options
          form_name = @model_options.first.to_s.camelize
        else
          form_name = name.sub(/Form$/, "")
        end
         # FIXME.

        active_model_name_for(form_name)
      end

    private
      def active_model_name_for(string)
        return ::ActiveModel::Name.new(OpenStruct.new(:name => string)) if rails_3_0?
        ::ActiveModel::Name.new(self, nil, string)
      end

      def rails_3_0?
        ::ActiveModel::VERSION::MAJOR == 3 and ::ActiveModel::VERSION::MINOR == 0
      end

      # The Rails FormBuilder "detects" nested attributes (which is what we want) by checking existance of a setter method.
      def add_nested_attribute_compat(name)
        define_method("#{name}_attributes=") {} # this is why i hate respond_to? in Rails.
      end
    end

    # Massage the incoming Rails params hash to be representable compliant.
    def validate(params)
      mapper.new(self).nested_forms do |attr, model| # FIXME: make this simpler.
        if attr.options[:form_collection] # FIXME: why no array?
          params[attr.name] = params["#{attr.name}_attributes"].values
        else
          params[attr.name] = params["#{attr.name}_attributes"]# DISCUSS: delete old key? override existing?
        end
      end

      res = super

      flatten_error_messages

      res
    end

  private
    def flatten_error_messages
      # FIXME: this is ugly on purpose, we will change the Errors API soon.
      nested_forms = mapper.new(self).nested_forms.each.to_a.map(&:first).map(&:name)
      collections =  mapper.new(self).nested_forms.find_all do |attr, f|
        attr.options[:form_collection]
      end.map(&:first).map(&:name)

      old_msgs = errors.messages

      flat_errors = {}
       old_msgs.each do |name, errs|
         next unless nested_forms.include?(name.to_s)

         # DISCUSS: this is horrible, but Rails wants this.
         errors.delete(name)

         errs.each do |err|
          #flat_errors["#{name}.#{err.keys.first}"] = err.values.first

          #self.errors.add("#{name}.#{err.keys.first}", err.values.first)

          # FIXME: haha!!!!

          flat_errors["#{name}.#{err.keys.first}"] = err.values.first and next unless collections.include?(name.to_s)

          flat_errors["#{name}.#{err.values.first.first.keys.first}"] = err.values.first.first.values.first
         end
       end

       flat_errors.each do |k,v|
         errors.add(k, *v)
       end
    end
  end


  def self.included(base)
    base.class_eval do
      extend FormBuilderMethods::ClassMethods # FIXME.
      extend CompositionClassMethods
    end
  end

  module CompositionClassMethods # TODO: move to composition as this is only for on: code.
    def model(main_model, options={})
      super

      composition_model = options[:on] || main_model

      delegate composition_model => :model # #song => model.song
      delegate [:persisted?, :to_key, :to_param, :to_model] => composition_model  # #to_key => song.to_key

      alias_method main_model, composition_model # #hit => model.song.
    end
  end
end
