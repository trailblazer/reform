require 'delegate'
require 'reform/fields'
require 'reform/composition'
require 'reform/representer'

module Reform
  class Form  < SimpleDelegator
    # reasons for delegation:
    # presentation: this object is used in the presentation layer by #form_for.
    # problem: #form_for uses respond_to?(:email_before_type_cast) which goes to an internal hash in the actual record.
    # validation: this object also contains the validation rules itself, should be separated.
    # TODO: figure out #to_key issues.

    def initialize(mapper, composition)
      @mapper     = mapper
      @model      = composition
      representer = @mapper.new(composition)

      super Fields.new(representer.fields, representer.to_hash)  # decorate composition and transform to hash.
    end

    def validate(params)
      # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.
      update_with(params)

      valid?  # this validates on <Fields> using AM::Validations, currently.
    end

    def save
      # DISCUSS: we should never hit @mapper here (which writes to the models) when a block is passed.
      return yield self, to_nested_hash if block_given?

      @mapper.new(model).from_hash(to_hash) # DISCUSS: move to Composition?
    end

  private
    attr_accessor :mapper, :model

    def update_with(params)
      mapper.new(self).from_hash(params) # sets form properties found in params on self.
    end

    # Use representer to return current key-value form hash.
    def to_hash
      mapper.new(self).to_hash
    end

    def to_nested_hash
      model.nested_hash_for(to_hash)  # use composition to compute nested hash.
    end

    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations
  end
end