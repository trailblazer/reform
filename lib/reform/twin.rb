require 'disposable/twin'

module Reform
  module Twin
    def self.included(base)
      base.send :include, Disposable::Twin::Builder
      base.extend ClassMethods
    end

    module ClassMethods
      def twin(twin_class)
        super(twin_class) { |dfn| property dfn.name } # create readers to twin model.
      end
    end

    def initialize(model, options={})
      super(build_twin(model, options))
    end
  end
end