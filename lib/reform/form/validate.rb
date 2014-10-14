# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Update
    # IDEA: what if Populate was a Decorator that simply knows how to setup the Form object graph, nothing more? That would decouple
    # the population from the validation (good and bad as less customizable).

    # Go through all nested forms and call form.update!(hash).
    def from_hash(*)
      nested_forms do |attr|
        attr.merge!(
          # set parse_strategy: sync> # DISCUSS: that kills the :setter directive, which usually sucks. at least document this in :populator.
          :collection => attr[:collection], # TODO: Def#merge! doesn't consider :collection if it's already set in attr YET.
          :parse_strategy => :sync, # just use nested objects as they are.

          # :getter grabs nested forms directly from fields bypassing the reader method which could possibly be overridden for presentation.
          :getter      => lambda { |options| fields.send(options.binding.name) },
          :deserialize => lambda { |object, params, args| object.update!(params) },
        )

        # TODO: :populator now is just an alias for :instance. handle in ::property.
        attr.merge!(:instance => attr[:populator]) if attr[:populator]

        attr.merge!(:instance => Populator::PopulateIfEmpty.new) if attr[:populate_if_empty]
      end

      # FIXME: solve this with a dedicated Populate Decorator per Form.
      representable_attrs.each do |attr|
        attr.merge!(:parse_filter => Representable::Coercion::Coercer.new(attr[:coercion_type])) if attr[:coercion_type]

        attr.merge!(:skip_if => Skip::AllBlank.new) if attr[:skip_if] == :all_blank
        attr.merge!(:skip_parse => attr[:skip_if]) if attr[:skip_if]
      end


      representable_attrs.each do |attr|
        next if attr[:form]

        attr.merge!(:parse_filter => Changed.new)
      end

      super
    end
  end


  module Populator
    # This might change soon (e.g. moved into disposable).
    class PopulateIfEmpty
      include Uber::Callable

      def call(fields, fragment, *args)
        index   = args.first
        options = args.last
        binding = options.binding
        form    = binding.get

        parent_form =  options.user_options[:parent_form]

        # FIXME: test those cases!!!
        return form[index] if binding.array? and form and form[index] # TODO: this should be handled by the Binding.
        return form if !binding.array? and form
        # only get here when above form is nil.


        if binding[:populate_if_empty].is_a?(Proc)
          model = parent_form.instance_exec(fragment, options.user_options, &binding[:populate_if_empty]) # call user block.
        else
          model = binding[:populate_if_empty].new
        end

        form  = binding[:form].new(model) # free service: wrap model with Form. this usually happens in #setup.

        if binding.array?
          # TODO: please extract this into Disposable.
          fields = fields.send(:fields)

          fields.send("#{binding.setter}", []) unless fields.send("#{binding.getter}") # DISCUSS: why do I have to initialize this here?
          fields.send("#{binding.getter}")[index] = form
        else
          fields.send("#{binding.setter}", form) # :setter is currently overwritten by :parse_strategy.
        end
      end
    end # PopulateIfEmpty
  end


  module Skip
    class AllBlank
      include Uber::Callable

      def call(form, params, options)
        # TODO: hahahahahaha.
        properties = options.binding.representer_module.representer_class.representable_attrs[:definitions].keys

        properties.each { |name| params[name].present? and return false }
        true # skip
      end
    end
  end


  class Changed
    def call(fragment, params, options)
      # options is a Representable::Options object holding all the stakeholders. this is here becaues of pass_options: true.
      form = options.represented
      name = options.binding.name

      form.changed[name] = form.send(name) != fragment

      fragment
    end
  end

  # 1. Populate the form object graph so that each incoming object has a representative form object.
  # 2. Deserialize. This is wrong and should be done in 1.
  # 3. Validate the form object graph.
  def validate(params)
    update!(params)

    super() # run the actual validation on self.
  end

  # Some users use this method to pre-populate a form. Not saying this is right, but we'll keep
  # this method here.
  def update!(params)
    deserialize!(params)
  end

private
  def deserialize!(params)
    # using self here will call the form's setters like title= which might be overridden.
    # from_hash(params, parent_form: self)
    mapper.new(self).extend(Update).send(deserialize_method, params, :parent_form => self)
  end

  def deserialize_method
    :from_hash
  end
end
