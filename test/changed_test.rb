require 'test_helper'
require 'reform/form/coercion'

class ChangedTest < BaseTest
  class AlbumForm < Reform::Form
    include Coercion

    property :title

    property :hit do
      property :title
      property :length, type: Integer
      validates :title, :presence => true
    end

    collection :songs do
      property :title
      validates :title, :presence => true
    end

    property :band do # yepp, people do crazy stuff like that.
      property :label do
        property :name
        property :location
        validates :name, :presence => true
      end
      # TODO: make band a required object.
    end

    validates :title, :presence => true
  end

  Label = Struct.new(:name, :location)

  # setup: changed? is always false
  let (:form) { AlbumForm.new(Album.new("Drawn Down The Moon", Song.new("The Ripper", 9), [Song.new("Black Candles"), Song.new("The Ripper")], Band.new(Label.new("Cleopatra Records")))) }

  it { form.changed?(:title).must_equal false }
  it { form.changed?("title").must_equal false }
  it { form.hit.changed?(:title).must_equal false }
  it { form.hit.changed?.must_equal false }


  describe "#validate" do
    before { form.validate(
      "title" => "Five", # changed.
      "hit"   => {"title"  => "The Ripper", # same, but overridden.
                  "length" => "9"}, # gets coerced, then compared, so not changed.
      "band"  => {"label" => {"name" => "Shrapnel Records"}} # only label.name changes.
    ) }

    it { form.changed?(:title).must_equal true }

    # it { form.changed?(:hit).must_equal false }

    # overridden with same value is no change.
    it { form.hit.changed?(:title).must_equal false }
    # coerced value is identical to form's => not changed.
    it { form.hit.changed?(:length).must_equal false }

    # it { form.changed?(:band).must_equal true }
    # it { form.band.changed?(:label).must_equal true }
    it { form.band.label.changed?(:name).must_equal true }

    # not present key/value in #validate is no change.
    it { form.band.label.changed?(:location).must_equal false }
    # TODO: parent form changed when child has changed!
  end
end