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
    twin = Struct.new(:invoice_date, :description)

    # Goal is to replace Reform's crazy horrible parsing layer with something traceable, easily
    # extendable and customizable. E.g. you can add steps for your own parsing etc.

    deserialize =
      {
        invoice_date: {
          parse: Class.new(Trailblazer::Activity::Railway) do
            step :read # TODO: what if not existing etc?
            step :parse_user_date
            step :coerce

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

              ctx[:parsed_value] = formatted
            end

            def coerce(ctx, parsed_value:, **)
              date = Types::Params::DateTime[parsed_value] # Does something along {DateTime.parse}.

              ctx[:coerced_value] = date
            end
          end
        },
        description: {
          parse: Class.new(Trailblazer::Activity::Railway) do
            step :read # TODO: what if not existing etc?
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
        step Subprocess(options[:parse]), id: field, input: [:input], inject: [{key: ->(*) { field }}], output: {:parsed_value => field, :value => :"#{field}.read", :coerced_value => :"#{field}.coerced"}
      end
    end


    form_params = {
      invoice_date: "12/11",
      description: "Lagavulin or whatever"
    }

    ctx = Trailblazer::Context({input: form_params}, {data: {}})
    signal, (ctx, _) = Trailblazer::Developer.wtf?(deserializer, [ctx, {}])

    pp ctx
  end



end
