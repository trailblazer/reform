module Reform::Form::Scalar
  def self.included(base)
    base.extend ClassMethods
    base.extend Forwardable
  end

  def update!(object)
    self.model = object
  end


  module ClassMethods
    def validates(name, options={})
      if name.is_a?(Hash)
        name, options = :model, name # per default, validate #model (e.g. "Hello").
      else
        def_delegator :model, name
      end

      super(name, options)
    end
  end
end