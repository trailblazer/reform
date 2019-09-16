class CallTest < Minitest::Spec
  Song = Struct.new(:title)

  class SongForm < TestForm
    property :title

    validation do
      required(:title).filled
    end
  end

  let(:form) { SongForm.new(Song.new) }

  it { form.(title: "True North").success?.must_equal true }
  it { form.(title: "True North").failure?.must_equal false }
  it { form.(title: "").success?.must_equal false }
  it { form.(title: "").failure?.must_equal true }

  it { form.(title: "True North").errors.messages.must_equal({}) }
  it { form.(title: "").errors.messages.must_equal(title: ["must be filled"]) }
end
