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

  it { assert form.(title: "True North").success? }
  it { refute form.(title: "True North").failure? }
  it { refute form.(title: "").success? }
  it { assert form.(title: "").failure? }

  it { assert_equal form.(title: "True North").errors.messages, {} }
  it { assert_equal form.(title: "").errors.messages, title: ["must be filled"] }
end
