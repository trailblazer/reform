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
    form.errors.to_s.must_equal "{:title=>[\"has already been taken\"]}"
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

class UniqueValidatorWithScopeTest < MiniTest::Spec
  class SongForm < Reform::Form
    include ActiveRecord

    property :album_id
    property :title
    validates :title, unique: { scope: :album_id }
  end

  it do
    Album.delete_all
    Song.delete_all

    album = Album.new
    album.save

    form = SongForm.new(Song.new)
    form.validate(album_id: album.id, title: 'How Many Tears').must_equal true
    form.save

    form = SongForm.new(Song.new)
    form.validate(album_id: album.id, title: 'How Many Tears').must_equal false
    form.errors.to_s.must_equal "{:title=>[\"has already been taken\"]}"

    album = Album.new
    album.save

    form = SongForm.new(Song.new)
    form.validate(album_id: album.id, title: 'How Many Tears').must_equal true
  end
end

class UniqueValidatorWithCollectionTest < MiniTest::Spec
  class AlbumForm < Reform::Form
    include ActiveRecord

    property :title
    validates :songs, unique: { scope: :title }

    collection :songs, :populate_if_empty => Song do
      property :title
    end
  end

  it do
    Album.delete_all
    Song.delete_all

    form = AlbumForm.new(Album.new)
    form.validate(songs: [{ title: 'Straight From The Jacket' }, { title: 'How Many Tears' }, { title: 'Straight From The Jacket' }]).must_equal false
    form.errors.to_s.must_equal "{:songs=>[\"has already been taken\"]}"

    album = Album.new
    form = AlbumForm.new(album)
    form.validate(songs: [{ title: 'Straight From The Jacket' }, { title: 'How Many Tears' }]).must_equal true
    form.save

    form.validate(songs: [{ title: 'How Many Tears' }]).must_equal false
    form.errors.to_s.must_equal "{:songs=>[\"has already been taken\"]}"
  end
end