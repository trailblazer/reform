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
          step :parse_user_date, output: ->(ctx, value:, **) { {:value => value, :"value.parsed" => value}}
          step :coerce, output: ->(ctx, value:, **) { {:value => value, :"value.coerced" => value}}


        end # :parse_block
      property :description

          def parse_user_date(ctx, value:, **)
            now_year = Time.now.strftime("%Y") # TODO: make injectable

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

      require "reform/form/dry"
      feature Reform::Form::Dry

      validation do
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


      # def validate!(name, pointers = [], values: self)
      #   super(name, pointers, values: bla)
      # end
    end


    twin = Struct.new(:invoice_date, :description)

    # Goal is to replace Reform's crazy horrible parsing layer with something traceable, easily
    # extendable and customizable. E.g. you can add steps for your own parsing etc.
    # * we can use Reform's {read}
    # * we apply custom parsing to invoice_date, e.g. "12" --> "12/10/2021"
    # * a separate step does coercion, using whatever code you want (or automatically via Dry::Types)
    # * we have all values separately after the deserialization and can assign it to a Twin as we need it. This allows
    #   to pass the coerced <DateTime> to the validation, but still show  the original "12" in the form when we error.
    #
    # NOTES
    # * the architecture of Contract#validate is great since we can easily replace the parsing of Form#validate.





    form_params = {
      invoice_date: "12/11",
      description: "Lagavulin or whatever",
      idont_exist: "true",
    }


    form = Form.new(twin.new)

    result = form.validate(form_params)
    assert_equal true, result
    assert_equal "#<DateTime: 2021-11-12T", form.invoice_date.inspect[0..22]


    result = form.validate({})
    assert_equal false, result
    assert_equal nil, form.invoice_date
    assert_equal %{{:invoice_date=>["must be DateTime"]}}, form.errors.messages.inspect


  # unit test: {deserializer}
    deserializer = Form.deserializer_activity
    ctx = Trailblazer::Context({input: form_params}, {data: {}})
    signal, (ctx, _) = Trailblazer::Developer.wtf?(deserializer, [ctx, {}], exec_context: form)

    assert_equal "12/11",             ctx[:"invoice_date.read"]
    assert_equal "12/11/2021",        ctx[:"invoice_date.parsed"]
    assert_equal "#<DateTime: 2021-", ctx[:"invoice_date.coerced"].inspect[0..16]
    assert_equal "#<DateTime: 2021-", ctx[:"invoice_date"].inspect[0..16] # ctx[:invoice_date] is the "effective" value for validation
    assert_equal "Lagavulin or whatever", ctx[:description]

    # def validate!(name, pointers = [], values: self, form: self)

    fields = form.instance_variable_get(:@fields).keys # FIXME: use schema!

    values = fields.collect { |field| ctx.key?(field) ? [field, ctx[field]] : nil }.compact.to_h
    # pp values
    result = form.validate!("bla", values: values)

    pp result
    pp ctx
  end



end
