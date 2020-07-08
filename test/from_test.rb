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

  it { _(subject.name).must_equal "Best Of" }
  it { _(subject.single.title).must_equal "Roxanne" }
  it { _(subject.tracks[0].name).must_equal "Fallout" }
  it { _(subject.tracks[1].name).must_equal "Roxanne" }

  describe "#validate" do

    before { subject.validate(params) }

    it { _(subject.name).must_equal "Best Of The Police" }
    it { _(subject.single.title).must_equal "So Lonely" }
    it { _(subject.tracks[0].name).must_equal "Message In A Bottle" }
    it { _(subject.tracks[1].name).must_equal "Roxanne" }
  end

  describe "#sync" do
    before do
      subject.tracks[1].name = "Livin' Ain't No Crime"
      subject.sync
    end

    it { _(song2.title).must_equal "Livin' Ain't No Crime" }
  end

  describe "#save (nested hash)" do
    before { subject.validate(params) }

    it do
      hash = nil

      subject.save do |nested_hash|
        hash = nested_hash
      end

      _(hash).must_equal({"title" => "Best Of The Police", "hit" => {"title" => "So Lonely"}, "songs" => [{"title" => "Message In A Bottle"}, {"title" => "Roxanne"}], "band" => nil})
    end
  end
end
