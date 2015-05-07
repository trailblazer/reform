require 'test_helper'

class ContractTest < BaseTest
  class AlbumContract < Reform::Contract
    property :title
    validates :title, :presence => true, :length => {:minimum => 3}

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
      validates :label, :presence => true

      property :label do
        property :name
        validates :name, :presence => true
      end
      # TODO: make band a required object.
    end
  end

  let (:album) { Album.new(nil, Song.new, [Song.new, Song.new], Band.new() ) }
  subject { AlbumContract.new(album) }


  describe "::representer" do
    # without name will always iterate.
    it do
      names = []
      AlbumContract.representer { |dfn| names << dfn.name }
      names.must_equal ["hit", "songs", "band"]

      # this doesn't cache.
      names = []
      AlbumContract.representer { |dfn| names << dfn.name }
      names.must_equal ["hit", "songs", "band"]
    end

    # with name caches representer per class and runs once.
    it do
      names = []
      AlbumContract.representer(:sync) { |dfn| names << dfn.name }
      names.must_equal ["hit", "songs", "band"]

      # this does cache.
      names = []
      AlbumContract.representer(:sync) { |dfn| names << dfn.name }
      names.must_equal []
    end

    # it allows iterating all properties, not only nested.
    it do
      names = []
      AlbumContract.representer(:save, all: true) { |dfn| names << dfn.name }
      names.must_equal ["title", "hit", "songs", "band"]

      names = []
      AlbumContract.representer(:save, all: true) { |dfn| names << dfn.name }
      names.must_equal []
    end

    # test :superclass?
  end

  class SongContract < Reform::Contract
    property :title, readable: true, type: String
  end

  describe "#options_for" do
    it { SongContract.new(OpenStruct.new).options_for(:title)[:coercion_type].must_equal String }
  end
end
