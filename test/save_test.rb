require 'test_helper'

class SaveTest < BaseTest
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
    let (:band) { Band.new(label) }
    let (:label) { Label.new }

    subject { ErrorsTest::AlbumForm.new(album) }

    before do
      [album, hit, song1, song2, band, label].each { |mdl| mdl.extend(Saveable) }

      subject.validate(params)
      subject.save
    end

    # synced?
    it { album.title.must_equal "Best Of" }
    it { hit.title.must_equal "Roxanne" }
    it { song1.title.must_equal "Fallout" }
    it { song2.title.must_equal "Roxanne" }
    it { label.name.must_equal "Polydor" }

    # saved?
    it { album.saved?.must_equal true }
    it { hit.saved?.must_equal true }
    it { song1.saved?.must_equal true }
    it { song1.saved?.must_equal true }
    it { band.saved?.must_equal true }
    it { label.saved?.must_equal true }
  end
end