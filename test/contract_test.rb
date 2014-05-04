require 'test_helper'

class ContractTest < MiniTest::Spec
  class AlbumContract < Reform::Contract
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

    validates :title, :presence => true, :length => {:minimum => 3}
  end

  let (:album) { Album.new(Song.new, [Song.new, Song.new], Band.new(Label.new) ) }
  subject { AlbumContract.new(Album) }

  describe "invalid" do
    before {
      res = subject.valid?
      res.must_be false
    }

    it { subject.errors.messages.must_equal({}) }
  end
end
