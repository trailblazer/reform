require 'test_helper'

class PrepopulateTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title, prepopulate: ->{ "Another Day At Work" }
    property :length

    property :hit, prepopulate: ->{ Song.new } do
      property :title

      property :band, prepopulate: ->{ Band.new } do
        property :name
      end
    end

    collection :songs, prepopulate: ->{ [Song.new, Song.new] } do
      property :title
    end
  end

  subject { AlbumForm.new(OpenStruct.new(length: 1)).prepopulate! }

  it { subject.length.must_equal 1 }
  it { subject.title.must_equal "Another Day At Work" }
  it { subject.hit.model.must_equal Song.new }
  it { subject.songs.size.must_equal 2 }
  it { subject.songs[0].model.must_equal Song.new }
  it { subject.songs[1].model.must_equal Song.new }
  it { subject.hit.band.model.must_equal Band.new }
end