require 'test_helper'

class FormOptionTest < MiniTest::Spec
  Song  = Struct.new(:title)
  Album = Struct.new(:song)

  class SongForm < Reform::Form
    property :title
    validates_presence_of :title
  end

  class AlbumForm < Reform::Form
    property :song, form: SongForm
  end

  it do
    AlbumForm.new(Album.new(Song.new("When It Comes To You"))).song.title.must_equal "When It Comes To You"
  end
end
