require 'test_helper'

class ErrorsTest < MiniTest::Spec
  class AlbumForm < Reform::Form
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

      validate :music_taste_ok?

    private
      def music_taste_ok?
        errors.add(:base, "You are a bad person") if name == 'Nickelback'
      end
    end

    validates :title, :presence => true
  end

  let (:album) do
    OpenStruct.new(
      :title  => "Blackhawks Over Los Angeles",
      :hit    => song,
      :songs  => songs, # TODO: document this requirement,

      :band => Struct.new(:name, :label).new("Epitaph", OpenStruct.new),
    )
  end
  let (:song)  { OpenStruct.new(:title => "Downtown") }
  let (:songs) { [song=OpenStruct.new(:title => "Calling"), song] }
  let (:form)  { AlbumForm.new(album) }


  describe "incorrect #validate" do
    before { form.validate(
      "hit"   =>{"title" => ""},
      "title" => "",
      "songs" => [{"title" => ""}, {"title" => ""}]) } # FIXME: what happens if item is missing?

    it do
      form.errors.messages.must_equal({
        :title  => ["can't be blank"],
        :"hit.title"=>["can't be blank"],
        :"songs.title"=>["can't be blank"],
        :"band.label.name"=>["can't be blank"]
      })
    end

    it do
      #form.errors.must_equal({:title  => ["can't be blank"]})
      # TODO: this should only contain local errors?
    end

    # nested forms keep their own Errors:
    it { form.hit.errors.messages.must_equal({:title=>["can't be blank"]}) }
    it { form.songs[0].errors.messages.must_equal({:title=>["can't be blank"]}) }

    it do
      form.errors.messages.must_equal({
        :title        => ["can't be blank"],
        :"hit.title"  => ["can't be blank"],
        :"songs.title"=> ["can't be blank"],
        :"band.label.name"=>["can't be blank"]
      })
    end
  end


  describe "#validate with main form invalid" do
    before { @result = form.validate("title"=>"", "band"=>{"label"=>{:name => "Fat Wreck"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:title=>["can't be blank"]}) }
  end


  describe "#validate with middle nested form invalid" do
    before { @result = form.validate("hit"=>{"title" => ""}, "band"=>{"label"=>{:name => "Fat Wreck"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"hit.title"=>["can't be blank"]}) }
  end


  describe "#validate with collection form invalid" do
    before { @result = form.validate("songs"=>[{"title" => ""}], "band"=>{"label"=>{:name => "Fat Wreck"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"songs.title"=>["can't be blank"]}) }
  end


  describe "#validate with collection and 2-level-nested invalid" do
    before { @result = form.validate("songs"=>[{"title" => ""}], "band" => {"label" => {}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"songs.title"=>["can't be blank"], :"band.label.name"=>["can't be blank"]}) }
  end

  describe "#validate with nested form using :base invalid" do
    it "xxx" do
      result = form.validate("songs"=>[{"title" => "Someday"}], "band" => {"name" => "Nickelback", "label" => {"name" => "Roadrunner Records"}})
      result.must_equal false
      form.errors.messages.must_equal({:base=>["You are a bad person"]})
    end
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


  describe "Errors#to_s" do
    before { form.validate("songs"=>[{"title" => ""}], "band" => {"label" => {}}) }

    # to_s is aliased to messages
    it { form.errors.to_s.must_equal "{:\"songs.title\"=>[\"can't be blank\"], :\"band.label.name\"=>[\"can't be blank\"]}" }
  end
end