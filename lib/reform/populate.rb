# FIXME: outdated comments
# Implements the :populator option.
#
#  populator: -> (fragment:, model:, :binding)
#  populator: -> (fragment:, collection:, index:, binding:)
#
# For collections, the entire collection and the currently deserialised index is passed in.
module Reform
  module Populate
    class Populator < Trailblazer::Activity::Railway
      def self.read_from_paired_model(ctx, model_from_populator:, key:, **)
        model_for_nested_property = model_from_populator.send(key) # DISCUSS: assumption is, we can call {model.title} or whatever

        ctx[:paired_model] = model_for_nested_property
      end

      step method(:read_from_paired_model)

      class IfEmpty < Populator
        def self.create_paired_model(ctx, populator:, **)
          ctx[:paired_model] = populator.() # FIXME: options? e.g. {fragment}
        end

        fail method(:create_paired_model), Output(:success) => Track(:success) # only called when {#read_from_paired_model} failed.
      end
    end



  #   def call(input, options)
  #     model = get(options)
  #     twin  = call!(options.merge(model: model, collection: model))

  #     return twin if twin == Representable::Pipeline::Stop

  #     # this kinda sucks. the proc may call self.composer = Artist.new, but there's no way we can
  #     # return the twin instead of the model from the #composer= setter.
  #     twin = get(options) unless options[:binding].array?

  #     # we always need to return a twin/form here so we can call nested.deserialize().
  #     handle_fail(twin, options)

  #     twin
  #   end

  # class IfEmpty < self # Populator
  #   def call!(options)
  #     binding, twin, index, fragment = options[:binding], options[:model], options[:index], options[:fragment] # TODO: remove once we drop 2.0.
  #     form = options[:represented]

  #     if binding.array?
  #       item = twin.original[index] and return item

  #       new_index = [index, twin.count].min # prevents nil items with initially empty/smaller collections and :skip_if's.
  #       # this means the fragment index and populated nested form index might be different.

  #       twin.insert(new_index, run!(form, fragment, options)) # form.songs.insert(Song.new)
  #     else
  #       return if twin

  #       form.send(binding.setter, run!(form, fragment, options)) # form.artist=(Artist.new)
  #     end
  end
end
