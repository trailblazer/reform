require 'test_helper'

class ContractTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class ArtistForm < Reform::Form
    property :name
  end

  class AlbumForm < Reform::Contract
    property :name
    validation do
      key(:name).required
    end

    collection :songs do
      property :title
      validation do
        key(:title).required
      end

      property :composer do
        property :name
        validation do
          key(:name).required
        end
      end
    end

    property :artist, form: ArtistForm
  end

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }
  let (:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let (:form) { AlbumForm.new(album) }

  # accept `property form: SongForm`.
  it do
    form.artist.must_be_instance_of ArtistForm
  end

  describe "#options_for" do
    it { AlbumForm.options_for(:name).extend(Declarative::Inspect).inspect.must_equal "#<Disposable::Twin::Definition: @options={:private_name=>:name, :name=>\"name\"}>" }
    it { AlbumForm.new(album).options_for(:name).extend(Declarative::Inspect).inspect.must_equal "#<Disposable::Twin::Definition: @options={:private_name=>:name, :name=>\"name\"}>" }
  end
end
