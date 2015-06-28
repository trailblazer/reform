module Reform
  module Schema
    def schema(options={})
      require "disposable/twin/schema"
      Disposable::Twin::Schema.from(self,
        {
          superclass:       Representable::Decorator,
          representer_from: lambda { |nested| nested.representer_class }
        }.merge(options) # TODO: options not tested.
      )
    end
  end
end
