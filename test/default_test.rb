require "test_helper"

class DefaultTest < Minitest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :name, default: "Wrong"

    collection :songs do
      property :title, default: "It's Catching Up"
    end
  end

  it do
    form = AlbumForm.new(Album.new(nil, [Song.new]))

    form.name.must_equal "Wrong"
    form.songs[0].title.must_equal "It's Catching Up"
  end
end