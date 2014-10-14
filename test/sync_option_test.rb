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


  describe ":sync allows you conditionals" do
    class BandForm < Reform::Form
      property :name, sync: lambda { |value, options| options.user_options[:form].changed?(:name) ? model.name = value : nil } # change if it hasn't changed
    end

    let (:band) { Band.new("Metallica") }
    let (:form) { BandForm.new(band) }

    # don't set name, didn't change.
    it do
      band.instance_exec { def name=(*); raise; end }
      form.validate("name" => "Metallica").must_equal true
      form.sync
      band.name.must_equal "Metallica"
    end

    # update name.
    it do
      form.validate("name" => "Iron Maiden").must_equal true
      form.sync
      form.name.must_equal "Iron Maiden"
    end
  end
end