module Reform::Form::Module
  def self.included(base)
    base.extend ClassMethods
    base.extend Included
  end

  module Included # TODO: use representable's inheritance mechanism.
    def included(base)
      super
      @instructions.each { |cfg| base.send(cfg[0], *cfg[1], &cfg[2]) } # property :name, {} do .. end
    end
  end

  module ClassMethods
    def property(*args, &block)
      instructions << [:property, args, block]
    end
    def validates(*args, &block)
      instructions << [:validates, args, block]
    end

    def instructions
      @instructions ||= []
    end
  end
end