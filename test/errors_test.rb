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

    validates :title, :presence => true
  end

  let (:album) do
    OpenStruct.new(
      :title  => "Blackhawks Over Los Angeles",
      :hit    => song,
      :songs  => songs # TODO: document this requirement
    )
  end
  let (:song)  { OpenStruct.new(:title => "Downtown") }
  let (:songs) { [OpenStruct.new(:title => "Calling")] }
  let (:form)  { AlbumForm.new(album) }


  describe "incorrect #validate" do
    before { form.validate(
      "hit"   =>{"title" => ""},
      "title" => "",
      "songs" => [{"title" => ""}]) }

    it do
      form.errors.messages.must_equal({
        :title  => ["can't be blank"],
        :"hit.title"=>["can't be blank"],
        :"songs.title"=>["can't be blank"]})
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
        :"songs.title"=> ["can't be blank"]})
    end # TODO: add another invalid item.
  end

  describe "#validate with main form invalid" do
    before { @result = form.validate("title"=>"") }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:title=>["can't be blank"]}) }
  end

  describe "#validate with middle nested form invalid" do
    before { @result = form.validate("hit"=>{"title" => ""}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"hit.title"=>["can't be blank"]}) }
  end

  describe "#validate with last nested form invalid" do
    before { @result = form.validate("songs"=>[{"title" => ""}]) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"songs.title"=>["can't be blank"]}) }
  end

  describe "correct #validate" do
    before { @result = form.validate(
      "hit"   => {"title" => "Sacrifice"},
      "title" => "Second Heat",
      "songs" => [{"title"=>"Heart Of A Lion"}]
      ) }

    it { @result.must_equal true }
    it { form.hit.title.must_equal "Sacrifice" }
    it { form.title.must_equal "Second Heat" }
    it { form.songs.first.title.must_equal "Heart Of A Lion" }
  end
end