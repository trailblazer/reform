require "test_helper"

class ReadonlyTest < MiniTest::Spec
  class SongForm < TestForm
    property :artist
    property :title, writeable: false
    # TODO: what to do with virtual values?
  end

  let(:form) { SongForm.new(OpenStruct.new) }

  it { refute form.readonly?(:artist) }
  it { assert form.readonly?(:title) }
end
