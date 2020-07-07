require "test_helper"

class AsTest < BaseTest
  class AlbumForm < TestForm
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

  let(:song2) { Song.new("Roxanne") }

  let(:params) do
      {
        "name" => "Best Of The Police",
        "single" => {"title" => "So Lonely"},
        "tracks" => [{"name" => "Message In A Bottle"}, {"name" => "Roxanne"}]
      }
    end

  subject { AlbumForm.new(Album.new("Best Of", hit, [Song.new("Fallout"), song2])) }

  it { assert_equal subject.name, "Best Of" }
  it { assert_equal subject.single.title, "Roxanne" }
  it { assert_equal subject.tracks[0].name, "Fallout" }
  it { assert_equal subject.tracks[1].name, "Roxanne" }

  describe "#validate" do

    before { subject.validate(params) }

    it { assert_equal subject.name, "Best Of The Police" }
    it { assert_equal subject.single.title, "So Lonely" }
    it { assert_equal subject.tracks[0].name, "Message In A Bottle" }
    it { assert_equal subject.tracks[1].name, "Roxanne" }
  end

  describe "#sync" do
    before do
      subject.tracks[1].name = "Livin' Ain't No Crime"
      subject.sync
    end

    it { assert_equal song2.title, "Livin' Ain't No Crime" }
  end

  describe "#save (nested hash)" do
    before { subject.validate(params) }

    it do
      hash = nil

      subject.save do |nested_hash|
        hash = nested_hash
      end

      assert_equal hash, "title" => "Best Of The Police", "hit" => {"title" => "So Lonely"}, "songs" => [{"title" => "Message In A Bottle"}, {"title" => "Roxanne"}], "band" => nil
    end
  end
end
