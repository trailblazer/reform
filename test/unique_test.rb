require "test_helper"

require "reform/form/validation/unique_validator.rb"
require "reform/form/active_record"

class UniquenessValidatorOnCreateTest < MiniTest::Spec
  class SongForm < Reform::Form
    include ActiveRecord
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
    include ActiveRecord
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


class UniqueWithCompositionTest < MiniTest::Spec
  class SongForm < Reform::Form
    include ActiveRecord
    include Composition

    property :title, on: :song
    validates :title, unique: true
  end

  it do
    Song.delete_all

    form = SongForm.new(song: Song.new)
    form.validate("title" => "How Many Tears").must_equal true
    form.save
  end
end