require "test_helper"

class ErrorsResultTest < Minitest::Spec
  MyResult = Struct.new(:success?, :errors) do
    def failure?; !success? end
  end

  # TODO: errors(args) not tested.

  describe "Contract::Result#success?" do
    let(:failed) { MyResult.new(false) }
    let(:succeeded) { MyResult.new(true) }

    it { assert_equal Reform::Contract::Result.new([failed, failed]).success?, false }
    it { assert_equal Reform::Contract::Result.new([succeeded, failed]).success?, false }
    it { assert_equal Reform::Contract::Result.new([failed, succeeded]).success?, false }
    it { assert Reform::Contract::Result.new([succeeded, succeeded]).success? }
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

    it { assert_equal Reform::Contract::Result.new(results).errors, {title: ["must be filled", "something more"], length: ["no Int"]} }
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
    it { assert_equal top.success?, false }
    it { assert_equal top.errors, errors }

    let(:artist) { Reform::Contract::Result::Pointer.new(MyResult.new(false, errors), [:artist]) }
    it { assert_equal artist.success?, false }
    it { assert_equal artist.errors,({age: ["too old"], bands: {0 => {name: "too new school"}, 1 => {name: "too boring"}}}) }

    let(:band) { Reform::Contract::Result::Pointer.new(MyResult.new(false, errors), [:artist, :bands, 1]) }
    it { assert_equal band.success?, false }
    it { assert_equal band.errors,({name: "too boring"}) }

    describe "advance" do
      let(:advanced) { artist.advance(:bands, 1) }

      it { assert_equal advanced.success?, false }
      it { assert_equal advanced.errors,({name: "too boring"}) }

      it { assert_nil artist.advance(%i[absolute nonsense]) }
    end
  end
end

# validation group:

# form.errors/messages/hint(*args)            ==> {:title: [..]}
#   @call_result.errors/messages/hint(*args) }

# # result = Result(original_result => [:band, :label], my_local_result => [] )
# # result.messages(locale: :en) merges original_result and my_local_result

# form.errors => Result(fetch tree of all nested forms.messages(*args))
