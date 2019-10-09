module Reform::Form::Dry
  module InputHash
    private

    # if dry_error is a hash rather than an array then it contains
    # the messages for a nested property
    # these messages need to be added to the correct collection
    # objects.

    # collections:
    # {0=>{:name=>["must be filled"]}, 1=>{:name=>["must be filled"]}}

    # Objects:
    # {:name=>["must be filled"]}
    # simply load up the object and attach the message to it

    # we can't use to_nested_hash as it get's messed up by composition.
    def input_hash(form)
      hash = form.class.nested_hash_representer.new(form).to_hash
      symbolize_hash(hash)
    end

    # dry-v needs symbolized keys
    # TODO: Don't do this here... Representers??
    def symbolize_hash(old_hash)
      old_hash.each_with_object({}) do |(k, v), new_hash|
        new_hash[k.to_sym] = if v.is_a?(Hash)
                               symbolize_hash(v)
                             elsif v.is_a?(Array)
                               v.map { |h| h.is_a?(Hash) ? symbolize_hash(h) : h }
                             else
                               v
                             end
      end
    end
  end
end
