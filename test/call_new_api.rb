require "test_helper"

class CallTest < Minitest::Spec
  Song = Struct.new(:title)

  class SongForm < TestForm
    property :title

    validation do
      params { required(:title).filled }
    end
  end

  let(:form) { SongForm.new(Song.new) }

  it { _(form.(title: "True North").success?).must_equal true }
  it { _(form.(title: "True North").failure?).must_equal false }
  it { _(form.(title: "").success?).must_equal false }
  it { _(form.(title: "").failure?).must_equal true }

  it { _(form.(title: "True North").errors.messages).must_equal({}) }
  it { _(form.(title: "").errors.messages).must_equal(title: ["must be filled"]) }
end
