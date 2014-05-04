require 'test_helper'

class ContractTest < BaseTest
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

    validates :songs, :length => {:minimum => 4}

    property :band do # yepp, people do crazy stuff like that.
      property :label do
        property :name
        validates :name, :presence => true
      end
      # TODO: make band a required object.
    end

    validates :title, :presence => true, :length => {:minimum => 3}
  end

  let (:album) { Album.new(nil, Song.new, [Song.new, Song.new], Band.new(Label.new) ) }
  subject { AlbumContract.new(album) }

  describe "invalid" do
    before {
      res = subject.valid?
      res.must_equal false
    }

    it { subject.errors.messages.must_equal({:songs=>["is too short (minimum is 4 characters)"], :title=>["can't be blank", "is too short (minimum is 3 characters)"]}) }
  end
end
