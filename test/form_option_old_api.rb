require "test_helper"

class FormOptionTest < MiniTest::Spec
  Song  = Struct.new(:title)
  Album = Struct.new(:song)

  class SongForm < TestForm
    property :title
    validation do
      required(:title).filled
    end
  end

  class AlbumForm < TestForm
    property :song, form: SongForm
  end

  it do
    form = AlbumForm.new(Album.new(Song.new("When It Comes To You")))
    _(form.song.title).must_equal "When It Comes To You"

    form.validate(song: {title: "Run For Cover"})
  end
end
