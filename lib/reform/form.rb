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
    super Fields.new(mapper.to_hash)
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
    yield self, @mapper.to_nested_hash if block_given?

    @mapper.save(self)
  end

  # FIXME: make AM optional.
  require 'active_model'
  include ActiveModel::Validations

  # Keeps values of the form fields. What's in here is to be displayed in the browser!
  # we need this intermediate object to display both "original values" and new input from the form after submitting.
  class Fields < OpenStruct
  end
end