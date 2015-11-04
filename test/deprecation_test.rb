require "test_helper"


class DeprecationRemoveMePopulatorTest < MiniTest::Spec
  Album = Struct.new(:songs)
  Song  = Struct.new(:title)


  class AlbumForm < Reform::Form
    collection :songs, populator: ->(fragment, collection, index, *) { return Representable::Pipeline::Stop if fragment[:title]=="Good"
      songs[index]
              } do
      property :title
    end
  end

  it do
    form = AlbumForm.new(Album.new([Song.new, Song.new]))
    hash = {songs: [{title: "Good"}, {title: "Bad"}]}

    form.validate(hash)

    form.songs.size.must_equal 2
    form.songs[0].title.must_equal nil
    form.songs[1].title.must_equal "Bad"
  end
end