require 'test_helper'

class SetupTest < BaseTest
  describe "populated" do
    subject { AlbumForm.new(Album.new("Best Of", hit, [Song.new("Fallout"), Song.new("Roxanne")])) }

    it { subject.title.must_equal "Best Of" }


    it { subject.hit.must_be_kind_of Reform::Form }
    it { subject.hit.title.must_equal "Roxanne" }

    it { subject.songs.must_be_kind_of Array }
    it { subject.songs.size.must_equal 2 }

    it { subject.songs[0].must_be_kind_of Reform::Form }
    it { subject.songs[0].title.must_equal "Fallout" }

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