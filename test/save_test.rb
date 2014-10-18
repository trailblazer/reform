require 'test_helper'

class SaveTest < BaseTest
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
      property :label do
        property :name
        validates :name, :presence => true
      end
      # TODO: make band a required object.
    end

    validates :title, :presence => true
  end

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

  subject { AlbumForm.new(album) }

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


class SaveWithDynamicOptionsTest < MiniTest::Spec
  Song = Struct.new(:id, :title, :length) do
    include Saveable
  end

  class SongForm < Reform::Form
    property :title#, save: false
    property :length, virtual: true
  end

  let (:song) { Song.new }
  let (:form) { SongForm.new(song) }

  # we have access to original input value and outside parameters.
  it "xxx" do
    form.validate("title" => "A Poor Man's Memory", "length" => 10)
    length_seconds = 120
    form.save(length: lambda { |value, options| form.model.id = "#{value}: #{length_seconds}" })

    song.title.must_equal "A Poor Man's Memory"
    song.length.must_equal nil
    song.id.must_equal "10: 120"
  end
end