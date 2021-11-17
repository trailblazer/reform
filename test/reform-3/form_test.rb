require "test_helper"
require "trailblazer/activity/dsl/linear"
require "trailblazer/developer"

require "dry/validation"
require "dry/types"
module Types
  include Dry.Types()
end

class FormTest < Minitest::Spec
  it "what" do
    class Form < Reform::Form
      property :invoice_date
      property :description

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

      def validate(input)


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

    deserialize =
      {
        invoice_date: {
          parse: Class.new(Trailblazer::Activity::Railway) do
            step :read, output: ->(ctx, value:, **) { {:value => value, :"value.read" => value}} # TODO: what if not existing etc?
            step :parse_user_date, output: ->(ctx, value:, **) { {:value => value, :"value.parsed" => value}}
            step :coerce, output: ->(ctx, value:, **) { {:value => value, :"value.coerced" => value}}

            def read(ctx, key:, input:, **)
              ctx[:value] = input[key]
            end

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
          end
        },
        description: {
          parse: Class.new(Trailblazer::Activity::Railway) do
            step :read, output: ->(ctx, value:, **) { {:value => value, :"value.read" => value}} # TODO: what if not existing etc?
            # step :parse_user_date
            # step :coerce

            def read(ctx, key:, input:, **)
              ctx[:value] = input[key]
            end
          end
        }
      }

    deserializer = Class.new(Trailblazer::Activity::Railway) do
      deserialize.each do |field, options|
        step Subprocess(options[:parse]), id: field, input: [:input], inject: [{key: ->(*) { field }}], output: {:"value.parsed" => :"#{field}.parsed", :"value.read" => :"#{field}.read", :"value.coerced" => :"#{field}.coerced", :value => field}
      end
    end


    form_params = {
      invoice_date: "12/11",
      description: "Lagavulin or whatever"
    }

    ctx = Trailblazer::Context({input: form_params}, {data: {}})
    signal, (ctx, _) = Trailblazer::Developer.wtf?(deserializer, [ctx, {}])

    assert_equal "12/11",             ctx[:"invoice_date.read"]
    assert_equal "12/11/2021",        ctx[:"invoice_date.parsed"]
    assert_equal "#<DateTime: 2021-", ctx[:"invoice_date.coerced"].inspect[0..16]
    assert_equal "#<DateTime: 2021-", ctx[:"invoice_date"].inspect[0..16] # ctx[:invoice_date] is the "effective" value for validation
    assert_equal "Lagavulin or whatever", ctx[:description]

    # def validate!(name, pointers = [], values: self, form: self)
    result = Form.new(twin.new).validate!("bla", values: ctx)

    pp result
    pp ctx
  end



end
