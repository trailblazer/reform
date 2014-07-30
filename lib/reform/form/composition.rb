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

    # Same as ActiveModel::model but allows you to define the main model in the composition
    # using +:on+.
    #
    # class CoverSongForm < Reform::Form
    #   model :song, on: :cover_song
    def model(main_model, options={})
      super

      composition_model = options[:on] || main_model

      # FIXME: this should just delegate to :model as in FB, and the comp would take care of it internally.
      [:persisted?, :to_key, :to_param].each do |method|
        define_method method do
          model[composition_model].send(method)
        end
      end

      self
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
    mapper.new(fields).to_hash(*args) # do not map names, yet. this happens in #to_nested_hash
  end

private
  def aliased_model # we don't need an Expose as we save the Composition instance in the constructor.
    model
  end
end
