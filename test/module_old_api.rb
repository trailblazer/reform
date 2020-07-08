require "test_helper"
require "reform/form/coercion"

class ModuleInclusionTest < MiniTest::Spec
  module BandPropertyForm
    include Reform::Form::Module

    property :artist
    property :band do
      property :title

      validation do
        required(:title).filled
      end

      def id # gets mixed into Form, too.
        2
      end
    end

    def id # gets mixed into Form, too.
      1
    end

    validation do
      required(:band).filled
    end

    include Dry::Types.module # allows using Types::* in module.
    property :cool, type: DRY_TYPES_CONSTANT::Bool # test coercion.

    module InstanceMethods
      def artist=(new_value)
        errors.add(:artist, "this needs to be filled") if new_value.nil?
        super(new_value)
      end
    end
  end

  # TODO: test if works, move stuff into inherit_schema!
  module AirplaysPropertyForm
    include Reform::Form::Module

    collection :airplays do
      property :station
      validation do
        required(:station).filled
      end
    end
    validation do
      required(:airplays).filled
    end
  end

  # test:
  # by including BandPropertyForm into multiple classes we assure that options hashes don't get messed up by AM:V.
  class HitForm < TestForm
    include BandPropertyForm
  end

  class SongForm < TestForm
    include Coercion
    property :title

    include BandPropertyForm
  end

  let(:song) { OpenStruct.new(band: OpenStruct.new(title: "Time Again"), artist: "Ketama") }

  # nested form from module is present and creates accessor.
  it { _(SongForm.new(song).band.title).must_equal "Time Again" }
  it { _(SongForm.new(song).artist).must_equal "Ketama" }

  # methods from module get included.
  it { _(SongForm.new(song).id).must_equal 1 }
  it { _(SongForm.new(song).band.id).must_equal 2 }

  # validators get inherited.
  it do
    form = SongForm.new(OpenStruct.new)
    form.validate(artist: nil)
    _(form.errors.messages).must_equal(artist: ["this needs to be filled"], band: ["must be filled"])
  end

  # coercion works
  it do
    form = SongForm.new(OpenStruct.new)
    form.validate({cool: "1"})
    _(form.cool).must_equal true
  end

  # include a module into a module into a class :)
  module AlbumFormModule
    include Reform::Form::Module
    include BandPropertyForm

    property :name
    validation do
      required(:name).filled
    end
  end

  class AlbumForm < TestForm
    include AlbumFormModule

    # pp heritage
    property :band, inherit: true do
      property :label
      validation do
        required(:label).filled
      end
    end
  end

  it do
    form = AlbumForm.new(OpenStruct.new(band: OpenStruct.new))
    form.validate("band" => {})
    _(form.errors.messages).must_equal("band.title": ["must be filled"], "band.label": ["must be filled"], name: ["must be filled"])
  end

  describe "module with custom accessors" do
    module SongModule
      include Reform::Form::Module

      property :id    # no custom accessor for id.
      property :title # has custom accessor.

      module InstanceMethods
        def title
          super.upcase
        end
      end
    end

    class IncludingSongForm < TestForm
      include SongModule
    end

    let(:song) { OpenStruct.new(id: 1, title: "Instant Mash") }

    it do
      _(IncludingSongForm.new(song).id).must_equal 1
      _(IncludingSongForm.new(song).title).must_equal "INSTANT MASH"
    end
  end
end
