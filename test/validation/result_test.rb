require "test_helper"

class ErrorsResultTest < Minitest::Spec
  MyResult = Struct.new(:success?, :errors) do
    def failure?; !success? end
  end

  # TODO: errors(args) not tested.

  describe "Contract::Result#success?" do
    let(:failed) { MyResult.new(false) }
    let(:succeeded) { MyResult.new(true) }

    it { _(Reform::Contract::Result.new([failed, failed]).success?).must_equal false }
    it { _(Reform::Contract::Result.new([succeeded, failed]).success?).must_equal false }
    it { _(Reform::Contract::Result.new([failed, succeeded]).success?).must_equal false }
    it { _(Reform::Contract::Result.new([succeeded, succeeded]).success?).must_equal true }
  end

  describe "Contract::Result#errors" do
    let(:results) do
      [
        MyResult.new(false, {length: ["no Int"]}),
        MyResult.new(false, {title: ["must be filled"], nested: {something: []}}),
        MyResult.new(false, {title: ["must be filled"], nested: {something: []}}),
        MyResult.new(false, {title: ["something more"], nested: {something: []}})
      ]
    end

    it { _(Reform::Contract::Result.new(results).errors).must_equal({title: ["must be filled", "something more"], length: ["no Int"]}) }
  end

  describe "Result::Pointer" do
    let(:errors) do # dry result #errors format.
      {
        title: ["ignore"],
        artist: {age: ["too old"],
          bands: {
            0 => {name: "too new school"},
            1 => {name: "too boring"},
          }
        }
      }
    end

    let(:top) { Reform::Contract::Result::Pointer.new(MyResult.new(false, errors), []) }
    it { _(top.success?).must_equal false }
    it { _(top.errors).must_equal errors }

    let(:artist) { Reform::Contract::Result::Pointer.new(MyResult.new(false, errors), [:artist]) }
    it { _(artist.success?).must_equal false }
    it { _(artist.errors).must_equal({age: ["too old"], bands: {0 => {name: "too new school"}, 1 => {name: "too boring"}}}) }

    let(:band) { Reform::Contract::Result::Pointer.new(MyResult.new(false, errors), [:artist, :bands, 1]) }
    it { _(band.success?).must_equal false }
    it { _(band.errors).must_equal({name: "too boring"}) }

    describe "advance" do
      let(:advanced) { artist.advance(:bands, 1) }

      it { _(advanced.success?).must_equal false }
      it { _(advanced.errors).must_equal({name: "too boring"}) }

      it { _(artist.advance(%i[absolute nonsense])).must_be_nil }
    end
  end
end

# validation group:

# form.errors/messages/hint(*args)            ==> {:title: [..]}
#   @call_result.errors/messages/hint(*args) }

# # result = Result(original_result => [:band, :label], my_local_result => [] )
# # result.messages(locale: :en) merges original_result and my_local_result

# form.errors => Result(fetch tree of all nested forms.messages(*args))
