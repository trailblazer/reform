require 'delegate'

class Form  < SimpleDelegator
  # reasons for delegation:
  # presentation: this object is used in the presentation layer by #form_for.
  # problem: #form_for uses respond_to?(:email_before_type_cast) which goes to an internal hash in the actual record.
  # validation: this object also contains the validation rules itself, should be separated.
  def to_key
    @mapper.to_key
  end

  #def self.model_name
  #  ActiveModel::Name.new(self, nil, "Student")
  #end

  def initialize(mapper) # model: new or existing?
    @mapper = mapper  # DISCUSS: not needed?
    # here the mapping between model(s) and form should happen.

    # this used to be our composition object with "magic" accessors:
    super Fields.new(mapper.attributes)
  end

  # workflow methods:
  def validate(params)
    # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.
    params.each do |k,v|
      send("#{k}=", v)
    end

    valid?
  end

  def save
    @mapper.save(self)
    yield self, @mapper.to_nested_hash if block_given?
  end

  # FIXME: make AM optional.
  require 'active_model'
  include ActiveModel::Validations

  # Keeps values of the form fields. What's in here is to be displayed in the browser!
  # we need this intermediate object to display both "original values" and new input from the form after submitting.
  class Fields < OpenStruct
  end

  # maps model(s) to form and back.
  class Mapper
    # DISCUSS: use representable here, like a boss.
    def initialize(objects)
      @objects = objects
    end

    class << self
      def attribute(name, opts)
        form_attributes << [name, opts]

        owner = opts[:on]
        define_method(owner) do
          @objects[owner]
        end
        delegate name, "#{name}=", to: owner
      end

      def attributes(names, *args)
        names.each do |name|
          attribute(name, *args)
        end
      end

      def form_attributes
        @form_attributes ||= []
      end
    end

    # contains all knowledge to present the "nested" setup to the form, which doesn't know internals of this.
    # DISCUSS: do we also map back here for saving? yes!

    # this returns a hash to fill the Form::Fields object
    # {email: email, grade: grade}
    def attributes
      hash = {}

      self.class.form_attributes.each do |cfg|
        hash[cfg.first] = send(cfg.first)
      end
      hash
    end

    # TODO: remove this to an optional layer since we don't want this everywhere (e.g. when using services).
    def save(attributes)
      self.class.form_attributes.each do |cfg|
        send("#{cfg.first}=", attributes.send(cfg.first))
      end
    end

    def to_nested_hash
      map = {}
      self.class.form_attributes.each do |cfg|
        map[cfg.last[:on]] ||= {}
        map[cfg.last[:on]][cfg.first] = send(cfg.first)
      end
      map
    end

  end
end