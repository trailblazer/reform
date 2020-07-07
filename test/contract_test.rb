require "test_helper"

class ContractTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :duration, :songs, :artist)
  Artist = Struct.new(:name)

  class ArtistForm < TestForm
    property :name
  end

  class AlbumForm < TestContract
    property :name

    properties :duration
    properties :year, :style, readable: false

    validation do
      params { required(:name).filled }
    end

    collection :songs do
      property :title
      validation do
        params { required(:title).filled }
      end

      property :composer do
        property :name
        validation do
          params { required(:name).filled }
        end
      end
    end

    property :artist, form: ArtistForm
  end

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", 123, [song, song_with_composer], artist) }

  let(:form) { AlbumForm.new(album) }

  # accept `property form: SongForm`.
  it do
    assert form.artist.is_a? ArtistForm
  end

  describe ".properties" do
    it "defines a property when called with one argument" do
      assert_respond_to form, :duration
    end

    it "defines several properties when called with multiple arguments" do
      assert_respond_to form, :year
      assert_respond_to form, :style
    end

    it "passes options to each property when options are provided" do
      readable = AlbumForm.new(album).options_for(:style)[:readable]
      assert_equal readable, false
    end

    it "returns the list of defined properties" do
      returned_value = AlbumForm.properties(:hello, :world, virtual: true)
      assert_equal returned_value, %i[hello world]
    end
  end

  describe "#options_for" do
    it { assert_equal AlbumForm.options_for(:name).extend(Declarative::Inspect).inspect, "#<Disposable::Twin::Definition: @options={:private_name=>:name, :name=>\"name\"}>" }
    it { assert_equal AlbumForm.new(album).options_for(:name).extend(Declarative::Inspect).inspect, "#<Disposable::Twin::Definition: @options={:private_name=>:name, :name=>\"name\"}>" }
  end
end
