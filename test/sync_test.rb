require 'test_helper'

class SyncTest < BaseTest

  Band = Struct.new(:name, :label)

  describe "populated" do
    let (:params) {
      {
        "title" => "Best Of",
        "hit"   => {"title" => "Roxanne"},
        "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}],
        :band  => {:label => {:name => "Polydor"}}
      }
    }

    let (:album) { Album.new(nil, hit, [song1, song2], band) }
    let (:hit) { Song.new }
    let (:song1) { Song.new }
    let (:song2) { Song.new }
    let (:band) { Band.new("The Police", label) }
    let (:label) { Label.new }

    subject { ErrorsTest::AlbumForm.new(album) }

    before do
      subject.validate(params)
      subject.sync
    end

    it { album.title.must_equal "Best Of" }
    it { album.hit.must_be_kind_of Struct }
    it { album.songs[0].must_be_kind_of Struct }
    it { album.songs[1].must_be_kind_of Struct }

    # it { hit.must_be_kind_of Struct }
    it { hit.title.must_equal "Roxanne" }
    it { song1.title.must_equal "Fallout" }
    it { song2.title.must_equal "Roxanne" }
    it { label.name.must_equal "Polydor" }
  end

  describe "with incoming nil value" do
    it do
      album = Album.new("GI")
      form  = ErrorsTest::AlbumForm.new(album)

      form.title.must_equal "GI"

      form.validate("title" => nil)
      form.title.must_equal nil
      form.sync
      album.title.must_equal nil
    end
  end
end