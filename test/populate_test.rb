require "test_helper"

class PopulatorTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :name
    validates :name, presence: true

    collection :songs,
      populator: lambda { |fragment, collection, index, options|
        # collection = options.binding.get # we don't need this anymore as this comes in for free!
        (item = collection[index]) ? item : collection.insert(index, Song.new) } do

      property :title
      validates :title, presence: true

      property :composer, populator: lambda { |fragment, model, *| model || self.composer= Artist.new } do
        property :name
        validates :name, presence: true
      end
    end

    # property :artist, populator: lambda { |fragment, options| (item = options.binding.get) ? item : Artist.new } do
    # NOTE: we have to document that model here is the twin!
    property :artist, populator: lambda { |fragment, twin, *| twin || self.artist = Artist.new } do
      property :name
    end
  end

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }
  let (:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let (:form) { AlbumForm.new(album) }

  # changing existing property :artist.
  # TODO: check with artist==nil
  it do
    old_id = artist.object_id

    form.validate(
      "artist" => {"name" => "Marcus Miller"}
    )

    form.artist.model.object_id.must_equal old_id
  end

  # use populator for default value on scalars?

  # adding to collection via :populator.
  # valid.
  it "yyy" do
    form.validate(
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne"},
        {"title" => "Rime Of The Ancient Mariner"}, # new song.
        {"title" => "Re-Education", "composer" => {"name" => "Rise Against"}}], # new song with new composer.
    ).must_equal true

    form.errors.messages.inspect.must_equal "{}"

    # form has updated.
    form.name.must_equal "The Dissent Of Man"
    form.songs[0].title.must_equal "Fallout"
    form.songs[1].title.must_equal "Roxanne"
    form.songs[1].composer.name.must_equal "Greg Graffin"

    form.songs[1].composer.model.must_be_instance_of Artist

    form.songs[1].title.must_equal "Roxanne"
    form.songs[2].title.must_equal "Rime Of The Ancient Mariner" # new song added.
    form.songs[3].title.must_equal "Re-Education"
    form.songs[3].composer.name.must_equal "Rise Against"
    form.songs.size.must_equal 4
    form.artist.name.must_equal "Bad Religion"


    # model has not changed, yet.
    album.name.must_equal "The Dissent Of Man"
    album.songs[0].title.must_equal "Broken"
    album.songs[1].title.must_equal "Resist Stance"
    album.songs[1].composer.name.must_equal "Greg Graffin"
    album.songs.size.must_equal 2
    album.artist.name.must_equal "Bad Religion"
  end
end

class PopulateIfEmptyTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }
  let (:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }



  class AlbumForm < Reform::Form
    property :name
    validates :name, presence: true

    collection :songs,
      populate_if_empty: Song do # class name works.

      property :title
      validates :title, presence: true

      property :composer, populate_if_empty: lambda { |*| Artist.new } do # lambda works, too.
        property :name
        validates :name, presence: true
      end
    end

    # TODO: test arguments in block.
    # TODO: test context of block.
    property :artist, populate_if_empty: lambda { |fragment, *| Artist.new } do
      property :name
    end
  end

  let (:form) { AlbumForm.new(album) }

  it do
    form.validate(
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne"},
        {"title" => "Rime Of The Ancient Mariner"}, # new song.
        {"title" => "Re-Education", "composer" => {"name" => "Rise Against"}}], # new song with new composer.
    ).must_equal true

    form.errors.messages.inspect.must_equal "{}"

    # form has updated.
    form.name.must_equal "The Dissent Of Man"
    form.songs[0].title.must_equal "Fallout"
    form.songs[1].title.must_equal "Roxanne"
    form.songs[1].composer.name.must_equal "Greg Graffin"
    form.songs[1].title.must_equal "Roxanne"
    form.songs[2].title.must_equal "Rime Of The Ancient Mariner" # new song added.
    form.songs[3].title.must_equal "Re-Education"
    form.songs[3].composer.name.must_equal "Rise Against"
    form.songs.size.must_equal 4
    form.artist.name.must_equal "Bad Religion"


    # model has not changed, yet.
    album.name.must_equal "The Dissent Of Man"
    album.songs[0].title.must_equal "Broken"
    album.songs[1].title.must_equal "Resist Stance"
    album.songs[1].composer.name.must_equal "Greg Graffin"
    album.songs.size.must_equal 2
    album.artist.name.must_equal "Bad Religion"
  end
end