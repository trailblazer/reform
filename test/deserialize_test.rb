require 'test_helper'
require "representable/json"

class DeserializeTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:title, :artist)
  Artist = Struct.new(:name, :callname)

  class JsonAlbumForm < Reform::Form
    module Json
      def deserialize(params)
        deserializer.new(self).
        # extend(Representable::Debug).
          from_json(params)
      end

      def deserializer
        Disposable::Rescheme.from(self.class,
          include:          [Representable::JSON],
          superclass:       Representable::Decorator,
          definitions_from: lambda { |inline| inline.definitions },
          options_from:     :deserializer,
          exclude_options:  [:populator]
        )
      end
    end
    include Json


    property :title
    property :artist, populate_if_empty: Artist do
      property :name
    end
  end


  let (:artist) { Artist.new("A-ha") }
  it do
    artist_id = artist.object_id

    form = JsonAlbumForm.new(Album.new("Best Of", artist))
    json = MultiJson.dump({title: "Apocalypse Soon", artist: {name: "Mute"}})

    form.validate(json)

    form.title.must_equal "Apocalypse Soon"
    form.artist.name.must_equal "Mute"
    form.artist.model.object_id.must_equal artist_id
  end

  describe "infering the deserializer from another form should NOT copy its populators" do
    class CompilationForm < Reform::Form
      property :artist, populator: ->(options) { self.artist = Artist.new(nil, options[:fragment].to_s) } do
        property :name
      end

      def deserializer
        super(JsonAlbumForm, include: [Representable::Hash])
      end
    end

    # also tests the Form#deserializer API. # FIXME.
    it "uses deserializer inferred from JsonAlbumForm but deserializes/populates to CompilationForm" do
      form = CompilationForm.new(Album.new)
      form.validate("artist"=> {"name" => "Horowitz"}) # the deserializer doesn't know symbols.
      form.sync
      form.artist.model.must_equal Artist.new("Horowitz", %{{"name"=>"Horowitz"}})
    end
  end
end


class ValidateWithBlockTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title
    property :artist, populate_if_empty: Artist do
      property :name
    end
  end

  it do
    album = Album.new
    form  = AlbumForm.new(album)
    json  = MultiJson.dump({title: "Apocalypse Soon", artist: {name: "Mute"}})

    deserializer = Disposable::Rescheme.from(AlbumForm,
      include:          [Representable::JSON],
      superclass:       Representable::Decorator,
      definitions_from: lambda { |inline| inline.definitions },
      options_from:     :deserializer
    )

    form.validate(json) do |params|
      deserializer.new(form).from_json(params)
    end.must_equal true # with block must return result, too.

    form.title.must_equal "Apocalypse Soon"
    form.artist.name.must_equal "Mute"
  end
end
