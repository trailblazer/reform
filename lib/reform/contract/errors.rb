{
  title: {
            failures: {
                        filled?: {
                                    message: "must be filled",
                                    invalid_input: ""
                                  },
                        presence: {
                                    essage: "can't be blank",
                                    invalid_input: ""
                                  }
                      }
          },
  hit: {
         title: {
                  failures: {
                              bad_title: {
                                           message: 'that is not a good hit title',
                                           invalid_input: 'Nickelback'
                                         }
                            }
                }
         failures: { # not sure if this kind of error will happen...
                     presence: { message: 'something', invalid_input: {} }
                   }
        }
}

class Reform::Contract::Error

end

class Reform::Contract::Error::Set < Hash
end

# errors[:hit][:title][:failures][:filled?][:message]

class Reform::Contract::Errors < Hash

  def add(attribute, errors, namespace = nil)
    if namespace && namespace != []
      fetch(namespace) { self[namespace] = [] }
      [namespace].fetch(attribute) { self[namespace][attribute] = [] } << errors
    else
      fetch(attribute) { self[attribute] = [] } << errors
    end
  end

  def merge!(errors, prefix)
    errors.each do |name, err|
      add(name, *err, prefix)
    end
  end

  def messages
    to_hash
  end

  def flat_messages
    # return messages in AM:E style
    # "title" => ['errors']
    # "author.name" => ['errors']
    #
    # maybe we won't even need this
    # maybe we can overide it from Reform::AM::V only to make it form_for "compliant"
  end

  def full_messages
    messages
  end
end
