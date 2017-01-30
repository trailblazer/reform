module Reform::Contract::Validate
  # attr_reader :errors # TODO: breaks when #validate wasn't called (and that's a GOOD THING.)

  def validate
    validate!(nil, [], nil).success?
  end

  def errors(*args)
    @result.errors(*args)
  end

  def validate!(name, path, pointer)
    # injected_errors: {:name=>["must be filled"], :label=>{:location=>["must be filled"]}}
    puts ">>> #{name.inspect}"

    # TODO: rename to Groups::Validate
    local_errors_by_group = Reform::Validation::Groups::Result.(self.class.validation_groups, self).compact # TODO: discss compact

local_errors_by_group = (local_errors_by_group+[pointer]) if pointer
    result = Reform::Contract::Result.new(local_errors_by_group) # also add injected pointers!


    unless pointer
      pointer = P.new(local_errors_by_group[0], [])
      puts "building new pointer%%%%%%%%%%%%"
    end

      nested_errors = validate_nested!(pointer ) # FIXME.

    @result = result
  end



  P = Reform::Contract::Result::Pointer

private

  # Recursively call validate! on nested forms.
  # Collect [ [:composer, #<Errors>], [:albums, #<Errors>]]
  def validate_nested!(pointer)
    # puts "@@@@@ #{pointer.inspect}"

    arr = []
    schema.each(twin: true) do |dfn|
      # on collections, this calls validate! on each item form.
      Disposable::Twin::PropertyProcessor.new(dfn, self).() { |form, i|

        puts "&&&&&& songs #{pointer.inspect}" if dfn[:name]=="songs"

        if nested_error = pointer[dfn[:name].to_sym]
          puts "   $$$$" if dfn[:name]=="songs" # SONGS DOESN'T HAVE ENTRY HERE.
          nested_error = nested_error[i] if i


          # local error has a nested element for us!
          path = pointer.instance_variable_get(:@path)
          res = pointer.instance_variable_get(:@result)
          puts "found (#{dfn[:name]}) #{nested_error}, #{path+[dfn[:name].to_sym, i].compact}x #{res}"

          pint = P.new(res, path+[dfn[:name].to_sym, i].compact)
          arr<<[ [dfn[:name], i], form.validate!(dfn[:name], nil, pint) ] and next
          # pointer = Reform::Contract::Result::Pointer.new(pointer, [dfn[:name]]))
        end

          puts "pionter: #{pint.inspect}"

        arr<<[ [dfn[:name], i], form.validate!(dfn[:name], nil, nil) ] }
    end
    arr
  end
end
