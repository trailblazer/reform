require "test_helper"

require "roar/json/hal"

class ExperimentalPopulatorTest < MiniTest::Spec
  Album = Struct.new(:songs)
  Song  = Struct.new(:title)


  class AlbumForm < Reform::Form
    collection :songs, populator: ->(options) { return Representable::Pipeline::Stop if options[:fragment][:title]=="Good"
      songs[options[:index]]
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