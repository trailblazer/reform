require 'test_helper'

class SyncOptionTest < MiniTest::Spec
  class SongForm < Reform::Form
    property :title
    property :image, sync: lambda { |value, *| model.image = "processed via :sync: #{value}" }#, virtual: true
    property :band do
      property :name, sync: lambda { |value, *| model.name = "band, processed: #{value}" }
    end
  end

  Song = Struct.new(:title, :image, :band)
  Band = Struct.new(:name)

  let (:song) { Song.new("Injection", Object, Band.new("Rise Against")) }

  # skips when not set.
  it do
    form = SongForm.new(song)

    form.validate("title" => "Ready To Fall")
    form.sync

    song.image.must_equal Object
    song.band.name.must_equal "Rise Against"
  end

  # uses :sync when present.
  it do
    form = SongForm.new(song)

    form.validate("title" => "Ready To Fall", "image" => Module, "band" => {"name" => Class})
    form.sync

    song.image.must_equal "processed via :sync: Module"
    song.band.name.must_equal "band, processed: Class"
  end
end