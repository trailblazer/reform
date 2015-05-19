# prepopulate!(options)
# prepopulator: ->(model, user_options)
module Reform::Form::Prepopulate
  def prepopulate!(options={})
    prepopulate_representer.new(self).to_object(options)

    # recursive_prepopulate_representer.new(self).to_hash # not sure if i leave that like this, consider private.
    self
  end

private
  def prepopulate_representer
    self.class.representer(:prepopulator, all: true, superclass: self.class.object_representer_class) do |dfn|
      next unless block = dfn[:prepopulator] or dfn[:twin]

        dfn.merge!(
          writer: Prepopulator.new(block),
        ) if block
    end
  end

  def recursive_prepopulate_representer
    self.class.representer(:recursive_prepopulate_representer) do |dfn|
      dfn.merge!(
        :serialize => lambda { |object, *| model = object.prepopulate! } # sync! returns the synced model.
        # representable's :setter will do collection=([..]) or property=(..) for us on the model.
      )
    end
  end


  class Prepopulator < Reform::Form::Populator
  private
    def call!(form, fragment, model, options)
      # FIXME: use U:::Value.
      form.instance_exec(model, options.user_options, &@user_proc) # pass user_options, we got access to everything.
    end

    def handle_fail(twin, options)
      # TODO: implement,
      # e.g. collections may return [] instead of one twin.
    end
  end
end