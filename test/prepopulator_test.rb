require 'test_helper'

class PrepopulatorTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title, prepopulator: ->(*){ self.title = "Another Day At Work" }
    property :length

    property :hit, prepopulator: ->(*){ self.hit = Song.new } do
      property :title

      property :band, prepopulator: ->(*){ self.band = Band.new } do
        property :name
      end
    end

    collection :songs, prepopulator: ->(*){ self.songs = [Song.new, Song.new] } do
      property :title
    end
  end

  it "ficken" do
    form = AlbumForm.new(OpenStruct.new(length: 1)).prepopulate!

    form.length.must_equal 1
    form.title.must_equal "Another Day At Work"
    form.hit.model.must_equal Song.new
    form.songs.size.must_equal 2
    form.songs[0].model.must_equal Song.new
    form.songs[1].model.must_equal Song.new
    form.songs[1].model.must_equal Song.new
    # prepopulate works more than 1 level, recursive.
    form.hit.band.model.must_equal Band.new
  end
end


class PrepopulateInFormContextTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title, prepopulator: ->(options){ "#{my_title} #{options.class}" }

    property :hit, prepopulator: ->(options){ my_hit } do
      property :title

      property :band, prepopulator: ->(options){ my_band } do
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
    collection :songs, prepopulator: ->(*){ songs.map(&:model) + [Song.new] } do
      property :title
    end
  end

  subject { AlbumForm.new(OpenStruct.new(songs: [Song.new])).prepopulate! }

  it { subject.songs.size.must_equal 2 }
  it { subject.songs[0].model.must_equal Song.new }
  it { subject.songs[1].model.must_equal Song.new }
end

# calling form.prepopulate! shouldn't crash.
class PrepopulateWithoutConfiguration < MiniTest::Spec
  Song = Struct.new(:title)

  class AlbumForm < Reform::Form
    collection :songs do
      property :title
    end

    property :hit do
      property :title
    end
  end

  subject { AlbumForm.new(OpenStruct.new(songs: [], hit: nil)).prepopulate! }

  it { subject.songs.size.must_equal 0 }
end