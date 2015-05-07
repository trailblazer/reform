require 'test_helper'

# tests: -------
# Contract
#   validate
#   errors

# Form
#   validate
#   errors

class ContractValidateTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Contract
    property :name
    validates :name, presence: true

    collection :songs do
      property :title
      validates :title, presence: true

      property :composer do
        validates :name, presence: true
        property :name
      end
    end

    property :artist do
      property :name
    end
  end

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }
  let (:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let (:form) { AlbumForm.new(album) }

  # valid
  it do
    form.validate.must_equal true
    form.errors.messages.inspect.must_equal "{}"
  end

  # invalid
  it do
    album.songs[1].composer.name = nil
    album.name = nil

    form.validate.must_equal false
    form.errors.messages.inspect.must_equal "{:\"songs.composer.name\"=>[\"can't be blank\"], :name=>[\"can't be blank\"]}"
  end
end


class ValidateWithDeserializerOptionTest < MiniTest::Spec
  Song  = Struct.new(:title, :album, :composer)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :name
    validates :name, presence: true

    collection :songs, pass_options: true,
      deserializer: {instance: lambda { |fragment, index, options|
              collection = options.binding.get
              (item = collection[index]) ? item : collection.insert(index, Song.new) },
      setter: nil} do

      property :title
      validates :title, presence: true

      property :composer, deserializer: { instance: lambda { |fragment, options| (item = options.binding.get) ? item : Artist.new } } do
        property :name
        validates :name, presence: true
      end
    end

    property :artist, deserializer: { instance: lambda { |fragment, options| (item = options.binding.get) ? item : Artist.new } } do
      property :name
    end
  end

  let (:song)               { Song.new("Broken") }
  let (:song_with_composer) { Song.new("Resist Stance", nil, composer) }
  let (:composer)           { Artist.new("Greg Graffin") }
  let (:artist)             { Artist.new("Bad Religion") }
  let (:album)              { Album.new("The Dissent Of Man", [song, song_with_composer], artist) }

  let (:form) { AlbumForm.new(album) }

  # valid.
  it do
    form.validate(
      "name"   => "Best Of",
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne", "composer" => {"name" => "Sting"}}],
      "artist" => {"name" => "The Police"},
    ).must_equal true

    form.errors.messages.inspect.must_equal "{}"

    # form has updated.
    form.name.must_equal "Best Of"
    form.songs[0].title.must_equal "Fallout"
    form.songs[1].title.must_equal "Roxanne"
    form.songs[1].composer.name.must_equal "Sting"
    form.artist.name.must_equal "The Police"


    # model has not changed, yet.
    album.name.must_equal "The Dissent Of Man"
    album.songs[0].title.must_equal "Broken"
    album.songs[1].title.must_equal "Resist Stance"
    album.songs[1].composer.name.must_equal "Greg Graffin"
    album.artist.name.must_equal "Bad Religion"
  end

  # invalid.
  it do
    form.validate(
      "name"   => "",
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne", "composer" => {"name" => ""}}],
      "artist" => {"name" => "The Police"},
    ).must_equal false

    form.errors.messages.inspect.must_equal "{:\"songs.composer.name\"=>[\"can't be blank\"], :name=>[\"can't be blank\"]}"
  end

  # adding to collection via :instance.
  # valid.
  it do
    form.validate(
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne"}, {"title" => "Rime Of The Ancient Mariner"}],
    ).must_equal true

    form.errors.messages.inspect.must_equal "{}"

    # form has updated.
    form.name.must_equal "The Dissent Of Man"
    form.songs[0].title.must_equal "Fallout"
    form.songs[1].title.must_equal "Roxanne"
    form.songs[1].composer.name.must_equal "Greg Graffin"
    form.songs[1].title.must_equal "Roxanne"
    form.songs[2].title.must_equal "Rime Of The Ancient Mariner" # new song added.
    form.songs.size.must_equal 3
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


#   # not sure if we should catch that in Reform or rather do that in disposable. this is https://github.com/apotonick/reform/pull/104
#   # describe ":populator with :empty" do
#   #   let (:form) {
#   #     Class.new(Reform::Form) do
#   #       collection :songs, :empty => true, :populator => lambda { |fragment, index, args|
#   #         songs[index] = args.binding[:form].new(Song.new)
#   #       } do
#   #         property :title
#   #       end
#   #     end
#   #    }

#   #   let (:params) {
#   #     {
#   #       "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
#   #     }
#   #   }

#   #   subject { form.new(Album.new("Hits", [], [])) }

#   #   before { subject.validate(params) }

#   #   it { subject.songs[0].title.must_equal "Fallout" }
#   #   it { subject.songs[1].title.must_equal "Roxanne" }
#   # end


#   describe ":populate_if_empty, half-populated collection" do
#     let (:form) {
#       Class.new(Reform::Form) do
#         collection :songs, :populate_if_empty => Song do
#           property :title
#         end
#       end
#      }

#     let (:params) {
#       {
#         "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
#       }
#     }
#     let (:song) { Song.new("Englishman") }

#     subject { form.new(Album.new("Hits", nil, [song])) }

#     before { subject.validate(params) }

#     it { subject.songs[0].model.object_id.must_equal song.object_id } # this song was existing before.
#     it { subject.songs[0].title.must_equal "Fallout" }
#     it { subject.songs[1].title.must_equal "Roxanne" }
#   end


#   describe ":populate_if_empty" do
#     let (:form) {
#       Class.new(Reform::Form) do
#         property :hit, :populate_if_empty => lambda { |fragment, args| Song.new } do
#           property :title
#         end

#         collection :songs, :populate_if_empty => lambda { |fragment, args| model.songs.build } do
#           property :title
#         end

#         property :band, :populate_if_empty => lambda { |fragment, args| Band.new } do
#           property :label, :populate_if_empty => lambda { |fragment, args| Label.new } do
#             property :name
#           end
#         end
#       end
#      }

#     let (:params) {
#       {
#         "hit"   => {"title" => "Roxanne"},
#         "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}],
#         "band"  => {"label" => {"name" => "Epitaph"}}
#       }
#     }

#     let (:song_collection_proxy) { Class.new(Array) { def build; Song.new; end } }
#     let (:album) { Album.new(nil,nil, song_collection_proxy.new, nil) }
#     subject { form.new(album) } # DISCUSS: require at least an array here? this is provided by all ORMs.

#     before { subject.validate(params) }

#     it { subject.hit.title.must_equal "Roxanne" }
#     it { subject.songs[0].title.must_equal "Fallout" }
#     it { subject.songs[1].title.must_equal "Roxanne" }

#     # population doesn't write to the model.
#     it { album.hit.must_equal nil }
#     it { album.songs.size.must_equal 0 }

#     it { subject.band.label.name.must_equal "Epitaph" }


#     describe "missing parameters" do
#       let (:params) {
#         { }
#       }

#       before { subject.validate(params) }

#       it { subject.hit.must_equal nil }
#     end
#   end


#   describe "populate_if_empty: Class" do
#     let (:form) {
#       Class.new(Reform::Form) do
#         property :hit, :populate_if_empty => Song do
#           property :title
#         end
#       end
#      }

#     let (:params) {
#       {
#         "hit"   => {"title" => "Roxanne"},
#       }
#     }

#     let (:album) { Album.new }
#     subject { form.new(album) }

#     before { subject.validate(params) }

#     it { subject.hit.title.must_equal "Roxanne" }
#   end



#   # test cardinalities.
#   describe "with empty collection and cardinality" do
#     let (:album) { Album.new }

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
#         subject.errors.messages[:hit].must_equal(["can't be blank"])
#         subject.errors.messages[:songs].first.must_match(/\Ais too short \(minimum is 1 characters?\)\z/)
#       end
#     end


#     describe "valid" do
#       let (:album) { Album.new(nil, Song.new, [Song.new("Urban Myth")]) }

#       before {
#         subject.validate({"songs" => [{"title"=>"Daddy, Brother, Lover, Little Boy"}], "hit" => {"title"=>"The Horse"}}).
#           must_equal true
#       }

#       it { subject.errors.messages.must_equal({}) }
#     end
#   end


#   describe "with symbols" do
#     let (:album) { OpenStruct.new(:band => OpenStruct.new(:label => OpenStruct.new(:name => "Epitaph"))) }
#     subject { ErrorsTest::AlbumForm.new(album) }
#     let (:params) { {:band => {:label => {:name => "Stiff"}}, :title => "House Of Fun"} }

#     before {
#       subject.validate(params).must_equal true
#     }

#     it { subject.band.label.name.must_equal "Stiff" }
#     it { subject.title.must_equal "House Of Fun" }
#   end


#   # providing manual validator method allows accessing form's API.
#   describe "with ::validate" do
#     let (:form) {
#       Class.new(Reform::Form) do
#         property :title

#         validate :title?

#         def title?
#           errors.add :title, "not lowercase" if title == "Fallout"
#         end
#       end
#      }

#     let (:params) { {"title" => "Fallout"} }
#     let (:song) { Song.new("Englishman") }

#     subject { form.new(song) }

#     before { @res = subject.validate(params) }

#     it { @res.must_equal false }
#     it { subject.errors.messages.must_equal({:title=>["not lowercase"]}) }
#   end


#   # overriding the reader for a nested form should only be considered when rendering.
#   describe "with overridden reader for nested form" do
#     let (:form) {
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

#      let (:album) { Album.new }

#      # don't use #artist when validating!
#      it do
#        form.validate("band" => {"label" => "Hellcat"}, "songs" => [{"title" => "Stand Your Ground"}, {"title" => "Otherside"}])
#        form.sync
#        album.band.label.must_equal "Hellcat"
#        album.songs.first.title.must_equal "Stand Your Ground"
#      end
#   end
# end