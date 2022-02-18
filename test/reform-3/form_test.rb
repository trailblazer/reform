require "test_helper"


require "dry/validation"
require "dry/types"
module Types
  include Dry.Types()
end

class FormTest < Minitest::Spec
  it "what" do
    class Form < Reform::Form
      property :invoice_date,
        parse_block: -> do
          # this goes after the {read} step.
          step :nilify, Output(:failure)=>Id(:set) # When {nilify} "fails" it means {:value} was a blank string.
          step :parse_user_date#, output: ->(ctx, value:, **) { {:value => value, :"value.parse_user_date" => value}}, provides: [:"value.parse_user_date"]
          step :coerce#, output: ->(ctx, value:, **) { {:value => value, :"value.coerce" => value}}, provides: [:"value.coerce"]
        end, # :parse_block
        parse_inject: [:now]

      property :description
      property :currency,
        parse_block: -> do
          # def self.default(ctx, **); true; end
          # step method(:default), after: :read, magnetic_to: :failure, Output(:success) => Track(:success), inject: [{ value: ->(ctx, **) {"EUR"} }], input: [:key], id: :default, field_name: :default  # we don't need {:value} here, do we?
          step Reform::Form::Property::Deserialize::Macro::Default(:currency, "EUR")
        end
      # TODO: {parse: false}
      property :created_at,
        read: false,
        parse_block: -> { step :populate_created_at }
      property :category, # no {parse_block}.
        read: false,
        set: false
      property :updated_at,
        parse_block: -> { step :parse_updated_at }
      property :notes, virtual: true

          def nilify(ctx, value:, **) # DISCUSS: move to lib? Do we want this here?
            ctx[:value] = nil if value == ""
            ctx[:value]
          end

          def parse_user_date(ctx, value:, now: Time.now, **)
            now_year = now.strftime("%Y")

            return false if value == "false"

            # allow dates like 24/12 or 24/12/17 because it's super handy.
            formatted = if match = value.match(/\d{1,2}[^\d]+\d{1,2}[^\d]+(\d{2})$/)
              value.sub(/#{match[1]}$/, "20#{match[1]}") # assuming this app won't be run in 21xx.
            elsif value.match(/\d{1,2}[^\d]+\d{1,2}$/)
              "#{value}/#{now_year}"
            else
              value
            end

            ctx[:value] = formatted
          end

          def coerce(ctx, value:, **)
            date = Types::Params::DateTime[value] # Does something along {DateTime.parse}.

            ctx[:value] = date
          end

          def populate_created_at(ctx, **)
            ctx[:value] = "Hello!" # TODO: test if we can access other shit
          end

          def parse_updated_at(ctx, deserialized_fields:, **)
            ctx[:value] = deserialized_fields.keys
          end

      require "reform/form/dry"
      feature Reform::Form::Dry

      validation group_class: Reform::Form::Dry::Validations::Group do
        params do
          # required(:source).filled
          # required(:unit_price) { float? } #(format?: /^([\d+\.{1},.]||[\d+,{1}\..]||\d+)$/)
          required(:invoice_date).value(type?: DateTime)

          # required(:txn_type).value( included_in?: %w(sale expense purchase receipt) )
          # required(:txn_account).value( included_in?: %w(bank paypal stripe) ) # DISCUSS: configurable?
        end
  # required(:currency).value(included_in?: Expense::Form.currencies.collect { |cfg| cfg.first })
        # required(:invoice_number).filled

        # required(:txn_direction).value( included_in?: %w(incoming outgoing) )
      end

      def lonesome_helper(what)
        %{#{what}?!!!}
      end

      def invoice_date_fmt
        self[:invoice_date].strftime("%F")
      end
    end


    twin = Struct.new(:invoice_date, :description, :currency, :created_at, :updated_at, :notes, :category)

    # Goal is to replace Reform's crazy horrible parsing layer with something traceable, easily
    # extendable and customizable. E.g. you can add steps for your own parsing etc.
    # * we can use Reform's {read}
    # * we apply custom parsing to invoice_date, e.g. "12" --> "12/10/2022"
    #   this is not possible using "filters" in dry-v where you can only apply a pattern, then coerce: https://dry-rb.org/gems/dry-schema/1.5/advanced/filtering/
    # * a separate step does coercion, using whatever code you want (or automatically via Dry::Types)
    # * we have all values separately after the deserialization and can assign it to a Twin as we need it. This allows
    #   to pass the coerced <DateTime> to the validation, but still show  the original "12" in the form when we error.
    # * it's possible to access all *pipeline variables* such as {invoice_date.parse_user_date} using {Form#[]}. It would be cool if this was probably routed to a "new" datastructure that only represents "validated" state.
    # * presenter layer has default readers for form builder, form itself is only other stuff
    # * property :created_at, inject: [:now]
    # * writing to form works with `#[]=`, e.g. for {file_data}
    #
    # NOTES
    # * the architecture of Contract#validate is great since we can easily replace the parsing of Form#validate.
    # * check "REFORM - What went wrong?" talk
    #
    # RENDERING LAYER

    # * overriding form readers for presentation/rendering with {#form_for} sucks:
=begin
    invalid do
      property :invoice_date => :"invoice_date.read" # use the original value when field is invalid
    # if form is invalid but {:invoice_date} is valid, show {:"invoice_date.parsed"}
    end
=end

    # TODO
    # * allow injecting an Errors object (operation/workflow wide)
    # * easy injection of dependencies
    # * how to access form instance in dry-v, e.g. for currency list?
    #
    # * {parse: false} option
    # * two steps Deserialize and Validate, so OPs could add steps? or allow steps in contracts?
    #   e.g. the {txn_direction} column could be set after the {type} parsing
    # * What're we doing with {Form#call}/{call.rb}?
    # * custom_errors
    # * readers in Form::New should be able to lookup {Default} value, or at least get a hint. also, TODO: can we use instance methods receiving ctx etc to compute {:default}?
    # * dynamic properties at validate: https://stackoverflow.com/questions/47916241/trailblazer-reform-gem-how-to-handle-this-type-of-input-validation
    # * proper inheritance for `validation do .. end` groups
    # * .dotted errors like it was done with {lib/reform/errors.rb}
    # * Reform::Module
    #  TODO: eg. rails form accessor shit
    # * test nested {:inject}
    # * popuplators skip!


    form_params = {
      invoice_date: "12/11",
      description: "Lagavulin or whatever",
      idont_exist: "true",
      # {:currency} is not present
      updated_at: "nil"
    }


    form = Form.new

    deserialized_form, validated_form = Reform::Form.validate(Form, form_params, {})
    # result = form.validate(form_params)
# pp form.instance_variable_get(:@arbitrary_bullshit)

    assert_equal "12/11",             validated_form[:"invoice_date.value.read"]
    assert_equal "12/11/2022",        validated_form[:"invoice_date.value.parse_user_date"]
    assert_equal "#<DateTime: 2022-11-12T", validated_form[:"invoice_date.value.coerce"].inspect[0..22]
    assert_equal "#<DateTime: 2022-11-12T", validated_form[:"invoice_date"].inspect[0..22] # validated_form[:invoice_date] is the "effective" value for validation
    assert_equal "Lagavulin or whatever", validated_form[:description]
    assert_equal true, validated_form.success?
    assert_equal "#<DateTime: 2022-11-12T", validated_form.invoice_date.inspect[0..22]

    assert_equal "EUR", validated_form.currency
    assert_equal nil, validated_form[:"currency.value.read"]
    # puts
    # puts validated_form.instance_variable_get(:@arbitrary_bullshit).keys
    assert_equal "EUR", validated_form[:"currency.value.default"]
# DISCUSS: do we want {:twin} here?
    assert_equal validated_form.updated_at.inspect, %{[:populated_instance, :form_instance, :input, :model_from_populator, :"invoice_date.value.read", :"invoice_date.value.nilify", :"invoice_date.value.parse_user_date", :"invoice_date.value.coerce", :invoice_date, :"description.value.read", :description, :"currency.value.read", :"currency.value.default", :currency, :"created_at.value.populate_created_at", :created_at, :category]}

  # test forwarding/delegation (# TODO: much more to be tested here)
  ## we can call a Form instance method (helper) from Deserialized.
  ## The form helper in turn can access deserialized data like {#invoice_date}.
    assert_equal %{Yo?!!!}, validated_form.lonesome_helper("Yo")
    # assert_equal validated_form.invoice_date_fmt, %{} #  FIXME: add this!


    deserialized_form, validated_form = Reform::Form.validate(Form, {}, {})
    assert_equal false, validated_form.success?
    assert_equal nil, validated_form.invoice_date
    assert_equal %{{:invoice_date=>["is missing"]}}, validated_form.errors.messages.inspect

    _form_params = {invoice_date: ""}
    deserialized_form, validated_form = Reform::Form.validate(Form, _form_params, {})
    assert_equal false, validated_form.success?
    assert_equal nil, validated_form.invoice_date
    assert_equal %{{:invoice_date=>["must be DateTime"]}}, validated_form.errors.messages.inspect


# test {:inject}
    injections = {now: Time.parse("23/11/2000")} # "ctx"
    # result = form.validate(Form_params, injections)
    deserialized_form, validated_form = Reform::Form.validate(Form, form_params, injections)

    assert_equal validated_form[:"invoice_date.value.parse_user_date"], "12/11/2000"

# test {parse: false}
    _form_params = {created_at: "rubbish, don't read me!", category: "Food and entertainment"}
    deserialized_form, validated_form = Reform::Form.validate(Form, _form_params, {})
    assert_equal "Hello!", validated_form.created_at
    assert_nil validated_form.category

# test {virtual: true}
    _form_params = {notes: "more rubbish, read me but don't set me!"}
    deserialized_form, validated_form = Reform::Form.validate(Form, _form_params, {})
    assert_equal "more rubbish, read me but don't set me!", validated_form.notes

# test {invoice_date} parse returns {false}
    _form_params = {invoice_date: "false"}
    deserialized_form, validated_form = Reform::Form.validate(Form, _form_params, {})
    assert_equal "false", validated_form.invoice_date


### ------ unit tests
  # setter
    validated_form[:notes] = "Add me!"
    assert_equal "Add me!", deserialized_form.notes # access {populated_instance}
    assert_equal "Add me!", validated_form.notes # access {populated_instance}
  # TODO: {disallow validated_form.notes=}
  # TODO: test if this gets synced/persisted.

return
  # unit test: {deserializer}
    deserializer = Form.deserializer_activity
    ctx = Trailblazer::Context({input: form_params}, {})
    signal, (ctx, _) = Trailblazer::Developer.wtf?(deserializer, [ctx, {}], exec_context: form)

    assert_equal "12/11",             ctx[:"invoice_date.value.read"]
    assert_equal "12/11/2022",        ctx[:"invoice_date.value.parse_user_date"]
    assert_equal "#<DateTime: 2022-", ctx[:"invoice_date.value.coerce"].inspect[0..16]
    assert_equal "#<DateTime: 2022-", ctx[:"invoice_date"].inspect[0..16] # ctx[:invoice_date] is the "effective" value for validation
    assert_equal "Lagavulin or whatever", ctx[:description]

    # def validate!(name, pointers = [], values: self, form: self)

    fields = form.instance_variable_get(:@fields).keys # FIXME: use schema!



    # values = fields.collect { |field| ctx.key?(field) ? [field, ctx[field]] : nil }.compact.to_h
    # # pp values
    # result = form.validate!("bla", values: values)

    # pp result
    # pp ctx
  end



end
