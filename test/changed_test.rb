require "test_helper"
require "reform/form/coercion"

class ChangedTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
    property :name

    collection :songs do
      property :title

      property :composer do
        property :name
      end
    end
  end

  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:album)              { Album.new("The Dissent Of Man", [song_with_composer]) }

  let(:form) { AlbumForm.new(album) }

  # nothing changed after setup.
  it do
    refute form.changed?(:name)
    refute form.songs[0].changed?(:title)
    refute form.songs[0].composer.changed?(:name)
  end

  # after validate, things might have changed.
  it do
    form.validate("name" => "Out Of Bounds", "songs" => [{"composer" => {"name" => "Ingemar Jansson & Mikael Danielsson"}}])
    assert form.changed?(:name)
    refute form.songs[0].changed?(:title)
    assert form.songs[0].composer.changed?(:name)
  end
end
