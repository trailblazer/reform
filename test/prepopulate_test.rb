require 'test_helper'

class PrepopulateTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title, prepopulate: ->(options){ "Another Day At Work" }
    property :length

    property :hit, prepopulate: ->(options){ Song.new } do
      property :title

      property :band, prepopulate: ->(options){ Band.new } do
        property :name
      end
    end

    collection :songs, prepopulate: ->(options){ [Song.new, Song.new] } do
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


class PrepopulateInFormContextTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title, prepopulate: ->(options){ "#{my_title} #{options.class}" }

    property :hit, prepopulate: ->(options){ my_hit } do
      property :title

      property :band, prepopulate: ->(options){ my_band } do
        property :name
      end

      def my_band
        Band.new
      end
    end

    def my_title
      "Rhode Island Shred"
    end

    def my_hit
      Song.new
    end
  end

  subject { AlbumForm.new(OpenStruct.new).prepopulate! }

  it { subject.title.must_equal "Rhode Island Shred Hash" }
  it { subject.hit.model.must_equal Song.new }
  it { subject.hit.band.model.must_equal Band.new }
end

class PrepopulateWithExistingCollectionTest < MiniTest::Spec
  Song = Struct.new(:title)

  class AlbumForm < Reform::Form
    collection :songs, prepopulate: ->(*){ songs.map(&:model) + [Song.new] } do
      property :title
    end
  end

  subject { AlbumForm.new(OpenStruct.new(songs: [Song.new])).prepopulate! }

  it { subject.songs.size.must_equal 2 }
  it { subject.songs[0].model.must_equal Song.new }
  it { subject.songs[1].model.must_equal Song.new }
end