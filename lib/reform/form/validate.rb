# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Update
    # Go through all nested forms and call form.update!(hash).
    def from_hash(*)
      nested_forms do |attr|
        attr.delete(:prepare)
        attr.delete(:extend)

        attr.merge!(
          :collection => attr[:collection], # TODO: Def#merge! doesn't consider :collection if it's already set in attr YET.
          :parse_strategy => :sync, # just use nested objects as they are.
          :deserialize => lambda { |object, params, args| object.update!(params) },
        )
      end

      super
    end
  end


  module Populator
    class PopulateIfEmpty
      def initialize(*args)
        @fields, @fragment, args = args
        @index = args.first
        @args  = args.last
      end

      def call
        binding = @args.binding
        form    = binding.get

        parent_form =  @args.user_options[:parent_form]
        form_model    = parent_form.model # FIXME: sort out who's responsible for sync.

        return if binding.array? and form and form[@index] # TODO: this should be handled by the Binding.
        return if !binding.array? and form
        # only get here when above form is nil.

        if binding[:populate_if_empty].is_a?(Proc)
          model = parent_form.instance_exec(@fragment, @args, &binding[:populate_if_empty]) # call user block.
        else
          model = binding[:populate_if_empty].new
        end

        form  = binding[:form].new(model) # free service: wrap model with Form. this usually happens in #setup.

        if binding.array?
          form_model.send("#{binding.getter}") << model # FIXME: i don't like this, but we have to add the model to the parent object to make associating work. i have to use #<< to stay compatible with AR's has_many API. DISCUSS: what happens when we get out-of-sync here?
          @fields.send("#{binding.getter}")[@index] = form
        else
          form_model.send("#{binding.setter}", model) # FIXME: i don't like this, but we have to add the model to the parent object to make associating work.
          @fields.send("#{binding.setter}", form) # :setter is currently overwritten by :parse_strategy.
        end
      end
    end # PopulateIfEmpty


    def from_hash(params, args)
      populated_attrs = []

      nested_forms do |attr|
        next unless attr[:populate_if_empty]

        attr.merge!(
          # DISCUSS: it would be cool to move the lambda block to PopulateIfEmpty#call.
          :populator => lambda do |fragment, *args|
            PopulateIfEmpty.new(self, fragment, args).call
          end
        )
      end


      nested_forms do |attr|
        next unless attr[:populator]

        attr.merge!(
          :parse_strategy => attr[:populator],
          :representable  => false
          )
        populated_attrs << attr.name.to_sym
      end

      super(params, {:include => populated_attrs}.merge(args))
    end
  end


  def validate(params)
    update!(params)

    super()
  end

  def update!(params)
    populate!(params)
    deserialize!(params)
  end

private
  def populate!(params)
    # populate only happens for nested forms, if you override that setter it's your fault.
    mapper.new(fields).extend(Populator).from_hash(params, :parent_form => self) # TODO: remove model(form) once we found out how to synchronize the model correctly. see https://github.com/apotonick/reform/issues/86#issuecomment-43402047
  end

  def deserialize!(params)
    # using self here will call the form's setters like title= which might be overridden.
    mapper.new(self).extend(Update).from_hash(params)
  end
end
