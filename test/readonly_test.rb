require "test_helper"

class ReadonlyTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :artist
    property :title, writeable: false
    # TODO: what to do with virtual values?
  end

  let (:form) { SongForm.new(OpenStruct.new) }

  it { form.readonly?(:artist).must_equal false }
  it { form.readonly?(:title).must_equal true }
end