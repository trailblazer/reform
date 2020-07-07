require "test_helper"

class PopulatorSkipTest < MiniTest::Spec
  Album = Struct.new(:songs)
  Song  = Struct.new(:title)

  class AlbumForm < TestForm
    collection :songs, populator: :my_populator do
      property :title
    end

    def my_populator(options)
      return skip! if options[:fragment][:title] == "Good"
      songs[options[:index]]
    end
  end

  it do
    form = AlbumForm.new(Album.new([Song.new, Song.new]))
    hash = {songs: [{title: "Good"}, {title: "Bad"}]}

    form.validate(hash)

    assert_equal form.songs.size, 2
    assert_nil form.songs[0].title
    assert_equal form.songs[1].title, "Bad"
  end
end
