require "test_helper"

class ReadonlyTest < MiniTest::Spec
  class SongForm < TestForm
    property :artist
    property :title, writeable: false
    # TODO: what to do with virtual values?
  end

  let(:form) { SongForm.new(OpenStruct.new) }

  it { _(form.readonly?(:artist)).must_equal false }
  it { _(form.readonly?(:title)).must_equal true }
end
