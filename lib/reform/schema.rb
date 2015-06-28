module Reform
  module Schema
    def schema
      require "disposable/twin/schema"
      Disposable::Twin::Schema.from(self,
        superclass:       Representable::Decorator,
        representer_from: lambda { |nested| nested.representer_class }
      )
    end
  end
end
