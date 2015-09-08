require "test_helper"

class AMValidationWithFormatTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :format
    validates :format, presence: true
  end

  class Song
    def format
      1
    end
  end

  it do
    SongForm.new(Song.new).validate({}).must_equal true
  end
end