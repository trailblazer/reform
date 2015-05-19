require 'test_helper'

class PrepopulatorTest < MiniTest::Spec
  Song = Struct.new(:title, :band, :length)
  Band = Struct.new(:name)

  class AlbumForm < Reform::Form
    property :title, prepopulator: ->(*){ self.title = "Another Day At Work" }                  # normal assignment.
    property :length

    property :hit, prepopulator: ->(model, options) { self.hit = Song.new(options[:title]) } do # use user options.
      property :title

      property :band, prepopulator: ->(*){ self.band = my_band } do                             # invoke your own code.
        property :name
      end

      def my_band
        Band.new
      end
    end

    collection :songs, prepopulator: ->(model, options) {
      if model == nil
        self.songs = [Song.new, Song.new]
      else
        model.insert(songs.size, Song.new)
      end  } do
        property :title
    end
  end

  it do
    form = AlbumForm.new(OpenStruct.new(length: 1)).prepopulate!(title: "Potemkin City Limits")

    form.length.must_equal 1
    form.title.must_equal "Another Day At Work"
    form.hit.model.must_equal Song.new("Potemkin City Limits")
    form.songs.size.must_equal 2
    form.songs[0].model.must_equal Song.new
    form.songs[1].model.must_equal Song.new
    form.songs[1].model.must_equal Song.new
    # prepopulate works more than 1 level, recursive.
    form.hit.band.model.must_equal Band.new
  end

  # add to existing collection.
  it do
    form = AlbumForm.new(OpenStruct.new(songs: [Song.new])).prepopulate!

    form.songs.size.must_equal 2
    form.songs[0].model.must_equal Song.new
    form.songs[1].model.must_equal Song.new
  end
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