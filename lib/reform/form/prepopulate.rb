# this will soon be handled in Disposable.
module Reform::Form::Prepopulate
  def prepopulate!
    # TODO: representer.new(fields).from_object(fields)
    hash = prepopulate_representer.new(fields).to_hash
    prepopulate_representer.new(fields).from_hash(hash)

    recursive_prepopulate_representer.new(fields).to_hash # not sure if i leave that like this, consider private.
    self
  end
private
  def prepopulate_representer
    self.class.representer(:prepopulate, :all => true) do |dfn|
      next unless block = dfn[:prepopulate] or dfn[:form]

      if dfn[:form]
        dfn.merge!(
          :render_filter => lambda do |v, h, options|
            object = options.binding[:prepopulate].call # TODO: execute in form context, pass options.

            if options.binding.array?
              object.collect { |item| options.binding[:form].new(item) }
            else
              options.binding[:form].new(object)
            end
          end,
          :representable  => false,

          :instance => lambda { |obj, *| obj } # needed for from_hash. TODO: make that in one go.
        )
      else
        dfn.merge!(:render_filter => lambda { |v, h, options| options.binding[:prepopulate].call }) # TODO: execute in form context, pass options.
      end
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

end