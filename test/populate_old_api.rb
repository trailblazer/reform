require "test_helper"

class PopulatorTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < TestForm
    property :name, populator: ->(options) { self.name = options[:fragment].reverse }
    validation do
      required(:name).filled
    end

    collection :songs,
               populator: ->(fragment:, model:, index:, **) {
                 (item = model[index]) ? item : model.insert(index, Song.new)
               } do
      property :title
      validation do
        required(:title).filled
      end

      property :composer, populator: ->(options) { options[:model] || self.composer = Artist.new } do
        property :name
        validation do
          required(:name).filled
        end
      end
    end

    # property :artist, populator: lambda { |fragment, options| (item = options.binding.get) ? item : Artist.new } do
    # NOTE: we have to document that model here is the twin!
    property :artist, populator: ->(options) { options[:model] || self.artist = Artist.new } do
      property :name
    end
  end

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let(:form) { AlbumForm.new(album) }

  it "runs populator on scalar" do
    form.validate(
      "name" => "override me!"
    )

    _(form.name).must_equal "!em edirrevo"
  end

  # changing existing property :artist.
  # TODO: check with artist==nil
  it do
    old_id = artist.object_id

    form.validate(
      "artist" => {"name" => "Marcus Miller"}
    )

    _(form.artist.model.object_id).must_equal old_id
  end

  # use populator for default value on scalars?

  # adding to collection via :populator.
  # valid.
  it "yyy" do
    _(form.validate(
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne"},
        {"title" => "Rime Of The Ancient Mariner"}, # new song.
        {"title" => "Re-Education", "composer" => {"name" => "Rise Against"}}], # new song with new composer.
    )).must_equal true

    _(form.errors.messages.inspect).must_equal "{}"

    # form has updated.
    _(form.name).must_equal "The Dissent Of Man"
    _(form.songs[0].title).must_equal "Fallout"
    _(form.songs[1].title).must_equal "Roxanne"
    _(form.songs[1].composer.name).must_equal "Greg Graffin"

    _(form.songs[1].composer.model).must_be_instance_of Artist

    _(form.songs[1].title).must_equal "Roxanne"
    _(form.songs[2].title).must_equal "Rime Of The Ancient Mariner" # new song added.
    _(form.songs[3].title).must_equal "Re-Education"
    _(form.songs[3].composer.name).must_equal "Rise Against"
    _(form.songs.size).must_equal 4
    _(form.artist.name).must_equal "Bad Religion"

    # model has not changed, yet.
    _(album.name).must_equal "The Dissent Of Man"
    _(album.songs[0].title).must_equal "Broken"
    _(album.songs[1].title).must_equal "Resist Stance"
    _(album.songs[1].composer.name).must_equal "Greg Graffin"
    _(album.songs.size).must_equal 2
    _(album.artist.name).must_equal "Bad Religion"
  end
end

class PopulateWithMethodTest < Minitest::Spec
  Album = Struct.new(:title)

  class AlbumForm < TestForm
    property :title, populator: :title!

    def title!(options)
      self.title = options[:fragment].reverse
    end
  end

  let(:form) { AlbumForm.new(Album.new) }

  it "runs populator method" do
    form.validate("title" => "override me!")

    _(form.title).must_equal "!em edirrevo"
  end
end

class PopulateWithCallableTest < Minitest::Spec
  Album = Struct.new(:title)

  class TitlePopulator
    include Uber::Callable

    def call(form, options)
      form.title = options[:fragment].reverse
    end
  end

  class AlbumForm < TestForm
    property :title, populator: TitlePopulator.new
  end

  let(:form) { AlbumForm.new(Album.new) }

  it "runs populator method" do
    form.validate("title" => "override me!")

    _(form.title).must_equal "!em edirrevo"
  end
end

class PopulateWithProcTest < Minitest::Spec
  Album = Struct.new(:title)

  TitlePopulator = ->(options) do
    options[:represented].title = options[:fragment].reverse
  end

  class AlbumForm < TestForm
    property :title, populator: TitlePopulator
  end

  let(:form) { AlbumForm.new(Album.new) }

  it "runs populator method" do
    form.validate("title" => "override me!")

    _(form.title).must_equal "!em edirrevo"
  end
end

class PopulateIfEmptyTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  class AlbumForm < TestForm
    property :name

    collection :songs,
      populate_if_empty: Song do                                                # class name works.

      property :title
      validation do
        required(:title).filled
      end

      property :composer, populate_if_empty: :populate_composer! do # lambda works, too. in form context.
        property :name
        validation do
          required(:name).filled
        end
      end

    private
      def populate_composer!(options)
        Artist.new
      end
    end

    property :artist, populate_if_empty: ->(args) { create_artist(args[:fragment], args[:user_options]) } do # methods work, too.
      property :name
    end

    private
    class Sting < Artist
      attr_accessor :args
    end
    def create_artist(input, user_options)
      Sting.new.tap { |artist| artist.args = ([input, user_options].to_s) }
    end
  end

  let(:form) { AlbumForm.new(album) }

  it do
    _(form.songs.size).must_equal 2

    _(form.validate(
      "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"},
        {"title" => "Rime Of The Ancient Mariner"}, # new song.
        {"title" => "Re-Education", "composer" => {"name" => "Rise Against"}}], # new song with new composer.
    )).must_equal true

    _(form.errors.messages.inspect).must_equal "{}"

    # form has updated.
    _(form.name).must_equal "The Dissent Of Man"
    _(form.songs[0].title).must_equal "Fallout"
    _(form.songs[1].title).must_equal "Roxanne"
    _(form.songs[1].composer.name).must_equal "Greg Graffin"
    _(form.songs[1].title).must_equal "Roxanne"
    _(form.songs[2].title).must_equal "Rime Of The Ancient Mariner" # new song added.
    _(form.songs[3].title).must_equal "Re-Education"
    _(form.songs[3].composer.name).must_equal "Rise Against"
    _(form.songs.size).must_equal 4
    _(form.artist.name).must_equal "Bad Religion"

    # model has not changed, yet.
    _(album.name).must_equal "The Dissent Of Man"
    _(album.songs[0].title).must_equal "Broken"
    _(album.songs[1].title).must_equal "Resist Stance"
    _(album.songs[1].composer.name).must_equal "Greg Graffin"
    _(album.songs.size).must_equal 2
    _(album.artist.name).must_equal "Bad Religion"
  end

  # trigger artist populator. lambda calling form instance method.
  it "xxxx" do
    form = AlbumForm.new(album = Album.new)
    form.validate("artist" => {"name" => "From Autumn To Ashes"})

    _(form.artist.name).must_equal "From Autumn To Ashes"
    # test lambda was executed in form context.
    _(form.artist.model).must_be_instance_of AlbumForm::Sting
    # test lambda block arguments.
    _(form.artist.model.args.to_s).must_equal "[{\"name\"=>\"From Autumn To Ashes\"}, nil]"

    assert_nil album.artist
  end
end

# delete songs while deserializing.
class PopulateIfEmptyWithDeletionTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)

  let(:song)  { Song.new("Broken") }
  let(:song2) { Song.new("Resist Stance") }
  let(:album) { Album.new("The Dissent Of Man", [song, song2]) }

  class AlbumForm < TestForm
    property :name

    collection :songs,
      populate_if_empty: Song, skip_if: :delete_song! do

      property :title
      validation do
        required(:title).filled
      end
    end

    def delete_song!(options)
      songs.delete(songs[0]) and return true if options[:fragment]["title"] == "Broken, delete me!"
      false
    end
  end

  let(:form) { AlbumForm.new(album) }

  it do
    _(form.validate(
      "songs" => [{"title" => "Broken, delete me!"}, {"title" => "Roxanne"}]
    )).must_equal true

    _(form.errors.messages.inspect).must_equal "{}"

    _(form.songs.size).must_equal 1
    _(form.songs[0].title).must_equal "Roxanne"
  end
end
