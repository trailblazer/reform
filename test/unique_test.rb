require "test_helper"

require "reform/form/validation/unique_validator.rb"

class UniquenessValidatorOnCreateTest < MiniTest::Spec
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

class UniquenessValidatorOnUpdateTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :title
    validates :title, unique: true
  end

  it do
    Song.delete_all
    @song = Song.create(title: "How Many Tears")

    form = SongForm.new(@song)
    form.validate("title" => "How Many Tears").must_equal true
    form.save

    form = SongForm.new(@song)
    form.validate("title" => "How Many Tears").must_equal true
  end
end
