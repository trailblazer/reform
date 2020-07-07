require "test_helper"

class PrepopulatorTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < TestForm
    property :title, prepopulator: ->(*) { self.title = "Another Day At Work" }                  # normal assignment.
    property :length

    property :hit, prepopulator: ->(options) { self.hit = Song.new(options[:title]) } do # use user options.
      property :title

      property :band, prepopulator: ->(options) { self.band = my_band(options[:title]) } do                             # invoke your own code.
        property :name
      end

      def my_band(name)
        Band.new(title)
      end
    end

    collection :songs, prepopulator: :prepopulate_songs! do
        property :title
    end

    private
    def prepopulate_songs!(options)
      if songs == nil
        self.songs = [Song.new, Song.new]
      else
        songs << Song.new # full Twin::Collection API available.
      end
    end
  end

  it do
    form = AlbumForm.new(OpenStruct.new(length: 1)).prepopulate!(title: "Potemkin City Limits")

    assert_equal form.length, 1
    assert_equal form.title, "Another Day At Work"
    assert_equal form.hit.model, Song.new("Potemkin City Limits")
    assert_equal form.songs.size, 2
    assert_equal form.songs[0].model, Song.new
    assert_equal form.songs[1].model, Song.new
    assert_equal form.songs[1].model, Song.new
    # prepopulate works more than 1 level, recursive.
    # it also passes options properly down there.
    assert_equal form.hit.band.model, Band.new("Potemkin City Limits")
  end

  # add to existing collection.
  it do
    form = AlbumForm.new(OpenStruct.new(songs: [Song.new])).prepopulate!

    assert_equal form.songs.size, 2
    assert_equal form.songs[0].model, Song.new
    assert_equal form.songs[1].model, Song.new
  end
end

# calling form.prepopulate! shouldn't crash.
class PrepopulateWithoutConfiguration < MiniTest::Spec
  Song = Struct.new(:title)

  class AlbumForm < TestForm
    collection :songs do
      property :title
    end

    property :hit do
      property :title
    end
  end

  subject { AlbumForm.new(OpenStruct.new(songs: [], hit: nil)).prepopulate! }

  it { assert_equal subject.songs.size, 0 }
end

class ManualPrepopulatorOverridingTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < TestForm
    property :title
    property :length

    property :hit do
      property :title

      property :band do
        property :name
      end
    end

    def prepopulate!(options)
      self.hit = Song.new(options[:title])
      super
    end
  end

  # you can simply override Form#prepopulate!
  it do
    form = AlbumForm.new(OpenStruct.new(length: 1)).prepopulate!(title: "Potemkin City Limits")

    assert_equal form.length, 1
    assert_equal form.hit.model, Song.new("Potemkin City Limits")
    assert_equal form.hit.title, "Potemkin City Limits"
  end
end
