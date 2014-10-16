module Reform::Form::Scalar
  # IDEA: what if every "leaf" property would be represented by a Scalar form?
  def self.included(base)
    base.extend ClassMethods
    base.extend Forwardable
  end

  def update!(object)
    @fields = object # @scalar is "I came from the outside." or <ArbitraryObject>.
  end

  def scalar
    fields
  end

  def save!
  end

  def sync!(*)
    model.replace(fields)
    # FIXME: how to sync that, if it's not responds to replace? or what if we don't want to write (e.g. image with paperdragon)?
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


  # TODO: change the way i hook into ::property.
  module Property
    private

    def property(name, options={}, &block)
      if options[:scalar]
        options.merge!(:features => [Reform::Form::Scalar], populate_if_empty: String)
      end

      super
    end
  end
end
