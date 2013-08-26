require 'test_helper'

class NestedFormTest < MiniTest::Spec
  class AlbumForm < Reform::Form
    property :title

    # class SongForm < Reform::Form
    #   property :title
    #   validates :title, :presence => true
    # end

    #form :hit, :class => SongForm
    property :hit do
      property :title
      validates :title, :presence => true
    end

    collection :songs do
      property :title
    end

    validates :title, :presence => true
  end

  # AlbumForm::collection :songs, :form => SongForm
  # should be: AlbumForm.new(songs: [Song, Song])

  let (:album) do
    OpenStruct.new(
      :title  => "Blackhawks Over Los Angeles",
      :hit    => song,
      :songs  => [OpenStruct.new(:title => "Calling")] # TODO: document this requirement
    )
  end
  let (:song) { OpenStruct.new(:title => "Downtown") }
  let (:form) { AlbumForm.new(album) }


  describe "incorrect #validate" do
    before { @result = form.validate("hit"=>{"title" => ""}, "title"=>"") }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:title=>["can't be blank"], :hit=>[{:title=>["can't be blank"]}]}) }
  end

  describe "#validate with main form invalid" do
    before { @result = form.validate("title"=>"") }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:title=>["can't be blank"]}) }
  end

  describe "#validate with nested form invalid" do
    before { @result = form.validate("hit"=>{"title" => ""}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:hit=>[{:title=>["can't be blank"]}]}) }
  end

  describe "correct #validate" do
    before { @result = form.validate("hit"=>{"title" => "Sacrifice"}, "title"=>"Second Heat") }

    it { @result.must_equal true }
    it { form.hit.title.must_equal "Sacrifice" }
    it { form.title.must_equal "Second Heat" }
  end

  it "responds to #to_hash" do
    form.to_hash.must_equal({"hit"=>{"title"=>"Downtown"}, "title" => "Blackhawks Over Los Angeles", "songs"=>[{"title"=>"Calling"}]})
  end

  it "creates nested forms" do
    form.hit.must_be_kind_of Reform::Form
    form.songs.must_be_kind_of Reform::Form::Forms
  end

  describe "rendering" do
    it { form.title.must_equal "Blackhawks Over Los Angeles" }
    it { form.hit.title.must_equal "Downtown" }
    it { form.songs[0].title.must_equal "Calling" }
  end

  describe "#save" do
    before { @result = form.validate("hit"=>{"title" => "Sacrifice"}, "title"=>"Second Heat",
      "songs" => [{"title" => "Scarified"}]) } # TODO: test empty/non-present songs

    it "updates internal Fields" do
      data = {}

      form.save do |f, nested_hash|
        data[:title]        = f.title
        data[:hit_title]    = f.hit.title
        data[:first_title]  = f.songs.first.title
      end

      data.must_equal(:title=>"Second Heat", :hit_title => "Sacrifice", :first_title => "Scarified")
    end

    it "passes form instances in first argument" do
      frm = nil

      form.save { |f, hsh| frm = f }

      frm.must_equal form
      frm.title.must_be_kind_of String
      frm.hit.must_be_kind_of Reform::Form
      frm.songs.first.must_be_kind_of Reform::Form
    end

    it "returns nested hash with symbol keys" do
      nested = nil

      form.save do |hash, nested_hash|
        nested = nested_hash
      end

      nested.must_equal(:title=>"Second Heat", :hit=>{"title"=>"Sacrifice"}, :songs=>[{"title"=>"Scarified"}])
    end

    it "pushes data to models" do
      form.save

      album.title.must_equal "Second Heat"
      song.title.must_equal "Sacrifice"
    end
  end

  # describe "with aliased nested form name" do
  #   let (:form) do
  #     Class.new(Reform::Form) do
  #       form :hit, :class => AlbumForm::SongForm, :as => :song
  #     end.new(OpenStruct.new(:hit => OpenStruct.new(:title => "")))
  #   end

  #   it "uses alias in errors" do
  #     form.validate({})
  #     form.errors.messages.must_equal({})
  #   end
  # end
end