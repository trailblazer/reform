require "reform/form/active_model"

module Reform::Form::Composition
  # Automatically creates a Composition object for you when initializing the form.
  def self.included(base)
    base.class_eval do
      extend Reform::Form::ActiveModel::ClassMethods # ::model.
      extend ClassMethods
    end
  end

  module ClassMethods
    #include Reform::Form::ActiveModel::ClassMethods # ::model.

    def model_class # DISCUSS: needed?
      @model_class ||= Reform::Composition.from(representer_class)
    end

    def property(name, options={})
      super.tap do |definition|
        handle_deprecated_model_accessor(options[:on]) unless options[:skip_accessors] # TODO: remove in 1.2.
      end
    end

    # Same as ActiveModel::model but allows you to define the main model in the composition
    # using +:on+.
    #
    # class CoverSongForm < Reform::Form
    #   model :song, on: :cover_song
    def model(main_model, options={})
      super

      composition_model = options[:on] || main_model

      handle_deprecated_model_accessor(composition_model)  unless options[:skip_accessors] # TODO: remove in 1.2.

      # FIXME: this should just delegate to :model as in FB, and the comp would take care of it internally.
      [:persisted?, :to_key, :to_param].each do |method|
        define_method method do
          model[composition_model].send(method)
        end
      end

      alias_method main_model, composition_model # #hit => model.song. # TODO: remove in 1.2.
    end

  private
    def handle_deprecated_model_accessor(name, aliased=name)
      define_method name do # form.band -> composition.band
        warn %{[Reform] Deprecation WARNING: When using Composition, you may not call Form##{name} anymore to access the contained model. Please use Form#model[:#{name}] and have a lovely day!}

        @model[name]
      end
    end
  end

  def initialize(models)
    composition = self.class.model_class.new(models)
    super(composition)
  end

  def to_nested_hash
    model.nested_hash_for(to_hash)  # use composition to compute nested hash.
  end

  def to_hash(*args)
    mapper.new(fields).to_hash(*args)
  end

private
  def aliased_model # we don't need an Expose as we save the Composition instance in the constructor.
    model
  end
end
