require 'test_helper'

class SetupTest < BaseTest
  class AlbumForm < Reform::Form
    property :title

    property :hit do
      property :title
      validates :title, :presence => true
    end

    collection :songs do
      property :title
      validates :title, :presence => true

      property :length do
        property :minutes
      end
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


  describe "populated" do
    subject { AlbumForm.new(Album.new("Best Of", hit, [Song.new("Fallout", Length.new(2,3)), Song.new("Roxanne")])) }

    it { subject.title.must_equal "Best Of" }


    it { subject.hit.must_be_kind_of Reform::Form }
    it { subject.hit.title.must_equal "Roxanne" }

    it { subject.songs.must_be_kind_of Array }
    it { subject.songs.size.must_equal 2 }

    it { subject.songs[0].must_be_kind_of Reform::Form }
    it { subject.songs[0].title.must_equal "Fallout" }
    it { subject.songs[0].length.minutes.must_equal 2 }

    it { subject.songs[1].must_be_kind_of Reform::Form }
    it { subject.songs[1].title.must_equal "Roxanne" }
  end


  describe "empty" do
    subject { AlbumForm.new(Album.new) }

    it { subject.title.must_equal nil }


# TODO: discuss and implement.
    # it { subject.hit.must_be_kind_of Reform::Form }
    # it { subject.hit.title.must_equal nil }


    # it { subject.songs.must_be_kind_of Reform::Form::Forms }
    # it { subject.songs.size.must_equal 0 }
  end
end