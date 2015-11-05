require "test_helper"

require 'reform/form/veto'

class VetoValidationsTest < MiniTest::Spec
  class AlbumForm < Reform::Form
    feature Reform::Form::Veto

    property :title

    property :hit do
      property :title
      validates :title, :presence => true
    end

    collection :songs do
      property :title
      validates :title, :presence => true
    end

    property :band do # yepp, people do crazy stuff like that.
      property :name
      property :label do
        property :name
        validates :name, :presence => true
      end
      # TODO: make band a required object.

      validate :validate_musical_taste

      def validate_musical_taste(entity)
        if entity.name == 'Nickelback' && entity.model.rating == 5
          errors.add(:base, "You are a bad person")
        end
      end
    end

    validates :title, :presence => true
  end

  class SongForm < Reform::Form
    feature Reform::Form::Veto

    property :title, validates: { presence: true }
  end

  let (:album) do
    OpenStruct.new(
      :title  => "Blackhawks Over Los Angeles",
      :hit    => song,
      :songs  => songs, # TODO: document this requirement,

      :band => Struct.new(:name, :label, :rating).new("Epitaph", OpenStruct.new, 5),
    )
  end
  let (:song)  { OpenStruct.new(:title => "Downtown") }
  let (:songs) { [song=OpenStruct.new(:title => "Calling"), song] }
  let (:form)  { AlbumForm.new(album) }
  let (:song_form) { SongForm.new(song) }


  # correct #validate.
  it do
    result = form.validate(
      "name"   => "Best Of",
      "songs"  => [{"title" => "Fallout"}, {"title" => "Roxanne", "composer" => {"name" => "Sting"}}],
      "artist" => {"name" => "The Police"},
      "band"   => {"label" => {"name" => "Epitaph"}},
    )

    result.must_equal true
    form.errors.inspect.must_equal "{}"

    song_result = song_form.validate(title: 'How you remind me')

    song_result.must_equal true
    song_form.errors.inspect.must_equal "{}"
  end


  describe "incorrect #validate" do
    it("xxx") do
      result = form.validate(
      "hit"   =>{"title" => ""},
      "title" => "",
      "songs" => [{"title" => ""}, {"title" => ""}])

      result.must_equal false

      form.errors.messages.inspect.must_match "title"
      form.errors.messages.inspect.must_match "hit.title"
      form.errors.messages.inspect.must_match "songs.title"
      form.errors.messages.inspect.must_match "band.label.name"


      form.hit.errors.messages.inspect.must_match "title"
      form.songs[0].errors.messages.inspect.must_match "title"

      form.errors.messages.must_equal({
        "title"  => ["is not present"],
        "hit.title"=>["is not present"],
        "songs.title"=>["is not present"],
        "band.label.name"=>["is not present"]
      })

      # nested forms keep their own Errors:
      form.hit.errors.messages.must_equal({:title => ["is not present"]})
      form.songs[0].errors.messages.must_equal({:title => ["is not present"]})

      form.errors.messages.must_equal({
        "title"        => ["is not present"],
        "hit.title"  => ["is not present"],
        "songs.title"=> ["is not present"],
        "band.label.name"=>["is not present"]
      })
    end
  end


  describe "#validate with collection form invalid" do
    it do
      result = form.validate("songs"=>[{"title" => ""}], "band"=>{"label"=>{:name => "Fat Wreck"}})
      result.must_equal false
      form.errors.messages.must_equal({"songs.title"=>["is not present"]})
      form.errors.messages.inspect.must_match "songs.title"
    end
  end


  describe "#validate with collection and 2-level-nested invalid" do
    it do
      result = form.validate("songs"=>[{"title" => ""}], "band" => {"label" => {}})
      result.must_equal false
      form.errors.messages.must_equal({"songs.title"=>["is not present"],
                                       "band.label.name"=>["is not present"]})
      form.errors.messages.inspect.must_match "songs.title"
      form.errors.messages.inspect.must_match "band.label.name"
    end
  end

  describe "#validate with nested form using :base invalid" do
    before { @result = form.validate("songs"=>[{"title" => "Someday"}],
      "band" => {"name" => "Nickelback", "label" => {"name" => "Roadrunner Records"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({'band.base'=>["You are a bad person"]}) }
  end

  describe "correct #validate" do
    before { @result = form.validate(
      "hit"   => {"title" => "Sacrifice"},
      "title" => "Second Heat",
      "songs" => [{"title"=>"Heart Of A Lion"}],
      "band"  => {"label"=>{:name => "Fat Wreck"}}
      ) }

    it { @result.must_equal true }
    it { form.hit.title.must_equal "Sacrifice" }
    it { form.title.must_equal "Second Heat" }
    it { form.songs.first.title.must_equal "Heart Of A Lion" }
  end
end


class VetoValidationsWithFormatTest < MiniTest::Spec
  class SongForm < Reform::Form
    feature Veto

    property :format
    validates :format, presence: true
  end

  class Song
    def format
      1
    end
  end

  it do
    SongForm.new(Song.new).validate({}).must_equal true
  end
end
