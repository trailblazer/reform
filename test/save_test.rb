require 'test_helper'

class SaveTest < BaseTest
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


  describe "save: false" do
    let (:form) {
      Class.new(Reform::Form) do
        property :hit do
          property :title
        end

        collection :songs, :save => false do
          property :title
        end

        property :band do # yepp, people do crazy stuff like that.
          property :label, :save => false do
            property :name
          end
          # TODO: make band a required object.
        end
      end
    }

    subject { form.new(album) }

    # synced?
    it { hit.title.must_equal "Roxanne" }
    it { song1.title.must_equal "Fallout" }
    it { song2.title.must_equal "Roxanne" }
    it { label.name.must_equal "Polydor" }

    # saved?
    it { album.saved?.must_equal true }
    it { hit.saved?.must_equal true }
    it { song1.saved?.must_equal nil }
    it { song1.saved?.must_equal nil }
    it { band.saved?.must_equal true }
    it { label.saved?.must_equal nil }
  end


  # #save returns result (this goes into disposable soon).
  it { subject.save.must_equal true }
  it do
    album.instance_eval { def save; false; end }
    subject.save.must_equal false
  end
end