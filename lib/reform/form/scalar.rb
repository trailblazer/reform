module Reform::Form::Scalar
  def self.included(base)
    base.extend ClassMethods
    base.extend Forwardable
  end

  def update!(object)
    model.replace(object)
  end


  module ClassMethods
    def validates(name, *args)
      if name.is_a?(Hash)
        name, args = :model, name # per default, validate #model (e.g. "Hello").
      else
        def_delegator :model, name
      end

      super(name, args)
    end
  end
end