require "test_helper"

class ContractValidateTest < MiniTest::Spec
  class AlbumForm < TestContract
    property :name
    validation do
      params { required(:name).filled }
    end

    collection :songs do
      property :title
      validation do
        params { required(:title).filled }
      end

      property :composer do
        validation do
          params { required(:name).filled }
        end
        property :name
      end
    end

    property :artist do
      property :name
    end
  end

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let(:form) { AlbumForm.new(album) }

  # valid
  it do
    assert form.validate
    assert_equal form.errors.messages.inspect, "{}"
  end

  # invalid
  it do
    album.songs[1].composer.name = nil
    album.name = nil

    assert_equal form.validate, false
    assert_equal form.errors.messages.inspect, "{:name=>[\"must be filled\"], :\"songs.composer.name\"=>[\"must be filled\"]}"
  end
end

# no configuration results in "sync" (formerly known as parse_strategy: :sync).
class ValidateWithoutConfigurationTest < MiniTest::Spec
  class AlbumForm < TestForm
    property :name
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

    property :artist do
      property :name
    end
  end

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let(:form) { AlbumForm.new(album) }

  # valid.
  it do
    object_ids = {
      song: form.songs[0].object_id, song_with_composer: form.songs[1].object_id,
      artist: form.artist.object_id, composer: form.songs[1].composer.object_id
    }

    assert form.validate(
      "name"   => "Best Of",
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne", "composer" => {"name" => "Sting"}}],
      "artist" => {"name" => "The Police"}
    )

    assert_equal form.errors.messages.inspect, "{}"

    # form has updated.
    assert_equal form.name, "Best Of"
    assert_equal form.songs[0].title, "Fallout"
    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[1].composer.name, "Sting"
    assert_equal form.artist.name, "The Police"

    # objects are still the same.
    assert_equal form.songs[0].object_id, object_ids[:song]
    assert_equal form.songs[1].object_id, object_ids[:song_with_composer]
    assert_equal form.songs[1].composer.object_id, object_ids[:composer]
    assert_equal form.artist.object_id, object_ids[:artist]

    # model has not changed, yet.
    assert_equal album.name, "The Dissent Of Man"
    assert_equal album.songs[0].title, "Broken"
    assert_equal album.songs[1].title, "Resist Stance"
    assert_equal album.songs[1].composer.name, "Greg Graffin"
    assert_equal album.artist.name, "Bad Religion"
  end

  # with symbols.
  it do
    assert form.validate(
      name:   "Best Of",
      songs:  [{title: "The X-Creep"}, {title: "Trudging", composer: {name: "SNFU"}}],
      artist: {name: "The Police"}
    )

    assert_equal form.name, "Best Of"
    assert_equal form.songs[0].title, "The X-Creep"
    assert_equal form.songs[1].title, "Trudging"
    assert_equal form.songs[1].composer.name, "SNFU"
    assert_equal form.artist.name, "The Police"
  end

  # throws exception when no populators.
  it do
    album = Album.new("The Dissent Of Man", [])

    assert_raises RuntimeError do
      AlbumForm.new(album).validate(songs: {title: "Resist-Stance"})
    end
  end
end

class ValidateWithInternalPopulatorOptionTest < MiniTest::Spec
  class AlbumForm < TestForm
    property :name
    validation do
      params { required(:name).filled }
    end

    collection :songs,
               internal_populator: ->(input, options) {
                 collection = options[:represented].songs
                 (item = collection[options[:index]]) ? item : collection.insert(options[:index], Song.new)
               } do
      property :title
      validation do
        params { required(:title).filled }
      end

      property :composer, internal_populator: ->(input, options) { (item = options[:represented].composer) ? item : Artist.new } do
        property :name
        validation do
          params { required(:name).filled }
        end
      end
    end

    property :artist, internal_populator: ->(input, options) { (item = options[:represented].artist) ? item : Artist.new } do
      property :name
      validation do
        params { required(:name).filled }
      end
    end
  end

  let(:song)               { Song.new("Broken") }
  let(:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let(:composer)           { Artist.new("Greg Graffin") }
  let(:artist)             { Artist.new("Bad Religion") }
  let(:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let(:form) { AlbumForm.new(album) }

  # valid.
  it("xxx") do
    assert form.validate(
      "name"   => "Best Of",
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne", "composer" => {"name" => "Sting"}}],
      "artist" => {"name" => "The Police"}
    )

    assert_equal form.errors.messages.inspect, "{}"

    # form has updated.
    assert_equal form.name, "Best Of"
    assert_equal form.songs[0].title, "Fallout"
    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[1].composer.name, "Sting"
    assert_equal form.artist.name, "The Police"

    # model has not changed, yet.
    assert_equal album.name, "The Dissent Of Man"
    assert_equal album.songs[0].title, "Broken"
    assert_equal album.songs[1].title, "Resist Stance"
    assert_equal album.songs[1].composer.name, "Greg Graffin"
    assert_equal album.artist.name, "Bad Religion"
  end

  # invalid.
  it do
    assert_equal form.validate(
      "name"   => "",
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne", "composer" => {"name" => ""}}],
      "artist" => {"name" => ""},
    ), false

    assert_equal form.errors.messages.inspect, "{:name=>[\"must be filled\"], :\"songs.composer.name\"=>[\"must be filled\"], :\"artist.name\"=>[\"must be filled\"]}"
  end

  # adding to collection via :instance.
  # valid.
  it do
    assert form.validate(
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne"}, {"title" => "Rime Of The Ancient Mariner"}]
    )

    assert_equal form.errors.messages.inspect, "{}"

    # form has updated.
    assert_equal form.name, "The Dissent Of Man"
    assert_equal form.songs[0].title, "Fallout"
    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[1].composer.name, "Greg Graffin"
    assert_equal form.songs[1].title, "Roxanne"
    assert_equal form.songs[2].title, "Rime Of The Ancient Mariner" # new song added.
    assert_equal form.songs.size, 3
    assert_equal form.artist.name, "Bad Religion"

    # model has not changed, yet.
    assert_equal album.name, "The Dissent Of Man"
    assert_equal album.songs[0].title, "Broken"
    assert_equal album.songs[1].title, "Resist Stance"
    assert_equal album.songs[1].composer.name, "Greg Graffin"
    assert_equal album.songs.size, 2
    assert_equal album.artist.name, "Bad Religion"
  end

  # allow writeable: false even in the deserializer.
  class SongForm < TestForm
    property :title, deserializer: {writeable: false}
  end

  it do
    form = SongForm.new(song = Song.new)
    form.validate("title" => "Ignore me!")
    assert_nil form.title
    form.title = "Unopened"
    form.sync # only the deserializer is marked as not-writeable.
    assert_equal song.title, "Unopened"
  end
end

# memory leak test
class ValidateUsingDifferentFormObject < MiniTest::Spec
  class AlbumForm < TestForm
    property :name

    validation do
      option :form

      params { required(:name).filled(:str?) }

      rule(:name) do
        if form.name == 'invalid'
          key.failure('Invalid name')
        end
      end
    end
  end

  let(:album) { Album.new }

  let(:form) { AlbumForm.new(album) }

  it 'sets name correctly' do
    assert form.validate(name: 'valid')
    form.sync
    assert_equal form.model.name, 'valid'
  end

  it 'validates presence of name' do
    refute form.validate(name: nil)
    assert_equal form.errors[:name], ["must be filled"]
  end

  it 'validates type of name' do
    refute form.validate(name: 1)
    assert_equal form.errors[:name], ["must be a string"]
  end

  it 'when name is invalid' do
    refute form.validate(name: 'invalid')
    assert_equal form.errors[:name], ["Invalid name"]
  end
end

#   # not sure if we should catch that in Reform or rather do that in disposable. this is https://github.com/trailblazer/reform/pull/104
#   # describe ":populator with :empty" do
#   #   let(:form) {
#   #     Class.new(Reform::Form) do
#   #       collection :songs, :empty => true, :populator => lambda { |fragment, index, args|
#   #         songs[index] = args.binding[:form].new(Song.new)
#   #       } do
#   #         property :title
#   #       end
#   #     end
#   #    }

#   #   let(:params) {
#   #     {
#   #       "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
#   #     }
#   #   }

#   #   subject { form.new(Album.new("Hits", [], [])) }

#   #   before { subject.validate(params) }

#   #   it { subject.songs[0].title.must_equal "Fallout" }
#   #   it { subject.songs[1].title.must_equal "Roxanne" }
#   # end

#   # test cardinalities.
#   describe "with empty collection and cardinality" do
#     let(:album) { Album.new }

#     subject { Class.new(Reform::Form) do
#       include Reform::Form::ActiveModel
#       model :album

#       collection :songs do
#         property :title
#       end

#       property :hit do
#         property :title
#       end

#       validates :songs, :length => {:minimum => 1}
#       validates :hit, :presence => true
#     end.new(album) }

#     describe "invalid" do
#       before { subject.validate({}).must_equal false }

#       it do
#         # ensure that only hit and songs keys are present
#         subject.errors.messages.keys.sort.must_equal([:hit, :songs])
#         # validate content of hit and songs keys
#         subject.errors.messages[:hit].must_equal(["must be filled"])
#         subject.errors.messages[:songs].first.must_match(/\Ais too short \(minimum is 1 characters?\)\z/)
#       end
#     end

#     describe "valid" do
#       let(:album) { Album.new(nil, Song.new, [Song.new("Urban Myth")]) }

#       before {
#         subject.validate({"songs" => [{"title"=>"Daddy, Brother, Lover, Little Boy"}], "hit" => {"title"=>"The Horse"}}).
#           must_equal true
#       }

#       it { subject.errors.messages.must_equal({}) }
#     end
#   end

#   # providing manual validator method allows accessing form's API.
#   describe "with ::validate" do
#     let(:form) {
#       Class.new(Reform::Form) do
#         property :title

#         validate :title?

#         def title?
#           errors.add :title, "not lowercase" if title == "Fallout"
#         end
#       end
#      }

#     let(:params) { {"title" => "Fallout"} }
#     let(:song) { Song.new("Englishman") }

#     subject { form.new(song) }

#     before { @res = subject.validate(params) }

#     it { @res.must_equal false }
#     it { subject.errors.messages.must_equal({:title=>["not lowercase"]}) }
#   end

#   # overriding the reader for a nested form should only be considered when rendering.
#   describe "with overridden reader for nested form" do
#     let(:form) {
#       Class.new(Reform::Form) do
#         property :band, :populate_if_empty => lambda { |*| Band.new } do
#           property :label
#         end

#         collection :songs, :populate_if_empty => lambda { |*| Song.new } do
#           property :title
#         end

#         def band
#           raise "only call me when rendering the form!"
#         end

#         def songs
#           raise "only call me when rendering the form!"
#         end
#       end.new(album)
#      }

#      let(:album) { Album.new }

#      # don't use #artist when validating!
#      it do
#        form.validate("band" => {"label" => "Hellcat"}, "songs" => [{"title" => "Stand Your Ground"}, {"title" => "Otherside"}])
#        form.sync
#        album.band.label.must_equal "Hellcat"
#        album.songs.first.title.must_equal "Stand Your Ground"
#      end
#   end
# end
