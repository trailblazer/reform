require 'test_helper'

class DeserializeTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class JsonAlbumForm < Reform::Form
    module Json
      def deserialize(params)
        # params = deserialize!(params) # DON'T call those hash hooks.

        deserializer.new(self).
        # extend(Representable::Debug).
          from_json(params)
      end

      def deserializer
        deserializer = Disposable::Twin::Schema.from(self.class,
          include:          [Representable::JSON],
          superclass:       Representable::Decorator,
          representer_from: lambda { |inline| inline.representer_class },
          options_from:     :deserializer
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
    json = {title: "Apocalypse Soon", artist: {name: "Mute"}}.to_json

    form.validate(json)

    form.title.must_equal "Apocalypse Soon"
    form.artist.name.must_equal "Mute"
    form.artist.model.object_id.must_equal artist_id
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
    json  = {title: "Apocalypse Soon", artist: {name: "Mute"}}.to_json

    deserializer = Disposable::Twin::Schema.from(AlbumForm,
      include:          [Representable::JSON],
      superclass:       Representable::Decorator,
      representer_from: lambda { |inline| inline.representer_class },
      options_from:     :deserializer
    )

    form.validate(json) do |params|
      deserializer.new(form).from_json(params)
    end.must_equal true # with block must return result, too.

    form.title.must_equal "Apocalypse Soon"
    form.artist.name.must_equal "Mute"
  end
end