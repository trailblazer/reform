# Include this in every module that gets further included.
# TODO: this could be implemented in Declarable, as we can use that everywhere.
module Reform::Form::Module
  def self.included(base)
    base.extend ClassMethods
    base.extend Included
  end

  module Included # TODO: use representable's inheritance mechanism.
    def included(base)
      super
      instructions.each { |cfg|
        args    = cfg[1].dup
        options = args.extract_options!.dup # we need to duplicate options has as AM::Validations messes it up later.

        base.send(cfg[0], *args, options, &cfg[2]) } # property :name, {} do .. end
    end
  end

  module ClassMethods
    def method_missing(method, *args, &block)
      instructions << [method, args, block]
    end

    def instructions
      @instructions ||= []
    end
  end
end