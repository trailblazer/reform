require "test_helper"

require "reform/form/validation/unique_validator.rb"

class UniquenessValidatorTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :title
    validates :title, unique: true
  end

  it do
    Song.delete_all

    form = SongForm.new(Song.new)
    form.validate("title" => "How Many Tears").must_equal true
    form.save

    form = SongForm.new(Song.new)
    form.validate("title" => "How Many Tears").must_equal false
    form.errors.to_s.must_equal "{:title=>[\"title must be unique.\"]}"
  end
end