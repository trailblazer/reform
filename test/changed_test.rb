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
    _(form.changed?(:name)).must_equal false
    _(form.songs[0].changed?(:title)).must_equal false
    _(form.songs[0].composer.changed?(:name)).must_equal false
  end

  # after validate, things might have changed.
  it do
    form.validate("name" => "Out Of Bounds", "songs" => [{"composer" => {"name" => "Ingemar Jansson & Mikael Danielsson"}}])
    _(form.changed?(:name)).must_equal true
    _(form.songs[0].changed?(:title)).must_equal false
    _(form.songs[0].composer.changed?(:name)).must_equal true
  end
end
