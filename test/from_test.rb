require 'test_helper'

class AsTest < BaseTest
  class AlbumForm < Reform::Form
    property :name, from: :title

    property :single, from: :hit do
      property :title
    end

    collection :tracks, from: :songs do
      property :name, from: :title
    end

    property :band do
      property :company, from: :label do
        property :business, from: :name
      end
    end
  end

  let (:song2) { Song.new("Roxanne") }

  let (:params) {
      {
        "name" => "Best Of The Police",
        "single"   => {"title" => "So Lonely"},
        "tracks" => [{"name" => "Message In A Bottle"}, {"name" => "Roxanne"}]
      }
    }

  subject { AlbumForm.new(Album.new("Best Of", hit, [Song.new("Fallout"), song2])) }

  it { subject.name.must_equal "Best Of" }
  it { subject.single.title.must_equal "Roxanne" }
  it { subject.tracks[0].name.must_equal "Fallout" }
  it { subject.tracks[1].name.must_equal "Roxanne" }


  describe "#validate" do


    before { subject.validate(params) }

    it { subject.name.must_equal "Best Of The Police" }
    it { subject.single.title.must_equal "So Lonely" }
    it { subject.tracks[0].name.must_equal "Message In A Bottle" }
    it { subject.tracks[1].name.must_equal "Roxanne" }
  end


  describe "#sync" do
    before {
      subject.tracks[1].name = "Livin' Ain't No Crime"
      subject.sync
    }

    it { song2.title.must_equal "Livin' Ain't No Crime" }
  end


  describe "#save (nested hash)" do
    before { subject.validate(params) }

    it do
      hash = nil

      subject.save do |nested_hash|
        hash = nested_hash
      end

      hash.must_equal({"title"=>"Best Of The Police", "hit"=>{"title"=>"So Lonely"}, "songs"=>[{"title"=>"Message In A Bottle"}, {"title"=>"Roxanne"}]})
    end
  end
end
