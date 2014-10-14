require 'test_helper'

class DirtyTest < BaseTest
  class AlbumForm < Reform::Form
    # register_feature ::Changed
    # include ::Changed

    property :title

    property :hit do
      property :title
      property :length
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

  # setup: changed? is always false
  let (:form) { AlbumForm.new(Album.new("Drawn Down The Moon", Song.new("The Ripper"), [Song.new("Black Candles"), Song.new("The Ripper")], Band.new(Label.new("Cleopatra Records")))) }

  it { form.changed?(:title).must_equal false }
  it { form.changed?("title").must_equal false }
  it { form.hit.changed?(:title).must_equal false }
  it { form.hit.changed?.must_equal false }

  describe "#validate" do
    before { form.validate(
      "title" => "Five", # changed.
      "hit"   => {"title" => "The Ripper"}, # same, but overridden.
      "band"  => {"label" => {"name" => "Shrapnel Records"}} # only label.name changes.
    ) }

    it { form.changed?(:title).must_equal true }
    # overridden with same value is no change.
    it { form.hit.changed?(:title).must_equal false }
    # not present key/value in #validate is no change.
    it { form.hit.changed?(:length).must_equal false }
    it { form.band.label.changed?(:name).must_equal true }

    # TODO: is that _after_ coercion?
  end
end