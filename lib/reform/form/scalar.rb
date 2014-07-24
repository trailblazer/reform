module Reform::Form::Scalar
  def self.included(base)
    base.extend ClassMethods
    base.extend Forwardable
  end

  def update!(object)
    @scalar = object # @scalar is "I came from the outside." or <ArbitraryObject>.
  end
  attr_reader :scalar # in a "real" form, this is fields.

  def save!
  end

  def sync!
    model.replace(scalar)
  end

  def to_nested_hash
    scalar
  end


  module ClassMethods
    def validates(name, options={})
      if name.is_a?(Hash)
        name, options = :scalar, name # per default, validate #scalar (e.g. "Hello").
      else
        def_delegator :scalar, name
      end

      super(name, options)
    end
  end
end