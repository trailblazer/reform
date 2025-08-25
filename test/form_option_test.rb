require "test_helper"

class FormOptionTest < Minitest::Spec
  Song  = Struct.new(:title)
  Album = Struct.new(:song)

  class SongForm < TestForm
    property :title
    validation do
      params { required(:title).filled }
    end
  end

  class AlbumForm < TestForm
    property :song, form: SongForm
  end

  it do
    form = AlbumForm.new(Album.new(Song.new("When It Comes To You")))
    assert_equal "When It Comes To You", form.song.title

    form.validate(song: {title: "Run For Cover"})
  end
end
