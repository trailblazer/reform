# Mechanics for writing to forms in #validate.
module Reform::Form::Validate
  module Representer
    def from_hash(*)
      nested_forms do |attr|
        attr.delete(:prepare)
        attr.delete(:extend)

        attr.merge!(
          :collection => attr[:collection], # TODO: Def#merge! doesn't consider :collection if it's already set in attr YET.
          :parse_strategy => :sync, # just use nested objects as they are.
          :deserialize => lambda { |object, params, args|

            options = args.user_options.dup
            options[:prefix] = options[:prefix].dup # TODO: implement Options#dup.
            options[:prefix] << args.binding.name # FIXME: should be #as.

            # puts "======= user_options: #{args.user_options.inspect}"

            object.validate!(params, options)
          },
        )
      end

      super
    end
  end


  module Populator
    def from_hash(params, *args)
      populated_attrs = []

      nested_forms do |attr|
        next unless attr[:populate_if_empty]

        attr.merge!(
          :populator => lambda do |fragment, *args|
            binding = args.last.binding

            model = binding.get

            return if binding.array? and model and model[args.first]
            return if !binding.array? and model

            #unless not_empty
              model = binding[:populate_if_empty].call(fragment, args.last) # call user block.
              form  = binding[:form].new(model) # free service: wrap model with Form.

              puts "[[[[[[[[[[[[[[[[[[ #{binding[:collection].inspect}"
              if binding.array?
                puts args.inspect
                send("#{binding.getter}")[args.first]= form
              else
                send("#{binding.setter}", form) # :setter is currently overwritten by :parse_strategy.
              end
            #end
          end
        )
      end


      nested_forms do |attr|
        next unless attr[:populator]

        attr.merge!(
          :parse_strategy => attr[:populator],
          # :collection => attr[:collection],
          :representable  => false
          )
        populated_attrs << attr.name.to_sym
      end

      super(params, {:include => populated_attrs})
    end
  end


  def validate(params)
    options = {:errors => errs = Errors.new(nil), :prefix => []}

    validate!(params, options)

    self.errors = errs # if the AM valid? API wouldn't use a "global" variable this would be better.

    errors.valid?
  end


  def validate!(params, options)
    populate!(params)

    # populate nested properties
    # update attributes of forms (from_hash)
    # run validate(errors) for all forms (no 1-level limitation anymore)

    # here it would be cool to have a validator object containing the validation rules representer-like and then pass it the formed model.

    # sets scalars and recurses #validate.
    prefix = options[:prefix]

    mapper.new(self).extend(Representer).from_hash(params, options) # calls validate(..) on nested.

    res = valid?  # this validates on <Fields> using AM::Validations, currently.

    options[:errors].merge!(self.errors, prefix)
  end

private
  attr_writer :errors # only used in top form.

  def populate!(params)
    mapper.new(self).extend(Populator).from_hash(params)
  end



  # The Errors class is planned to replace AM::Errors. It provides proper nested error messages.
  class Errors < ActiveModel::Errors
    def messages
      return super unless Reform.rails3_0?
      self
    end

    # def each
    #   messages.each_key do |attribute|
    #     self[attribute].each { |error| yield attribute, Array.wrap(error) }
    #   end
    # end

    def merge!(errors, prefix)
      prefixes = prefix.join(".")

      # TODO: merge into AM.
      errors.messages.each do |field, msgs|
        field = (prefix+[field]).join(".").to_sym # TODO: why is that a symbol in Rails?

        msgs = [msgs] if Reform.rails3_0? # DISCUSS: fix in #each?

        msgs.each do |msg|
          next if messages[field] and messages[field].include?(msg)
          add(field, msg)
        end # Forms now contains a plain errors hash. the errors for each item are still available in item.errors.
      end
    end

    def valid? # TODO: test me in unit test.
      blank?
    end
  end # Errors

end
