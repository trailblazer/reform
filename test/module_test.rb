require "test_helper"
require "reform/form/coercion"

class ModuleInclusionTest < Minitest::Spec
  module BandPropertyForm
    include Reform::Form::Module

    property :band do
      property :title

      validation do
        params { required(:title).filled }
      end

      def id # gets mixed into Form, too.
        2
      end
    end

    def id # gets mixed into Form, too.
      1
    end

    validation do
      params { required(:band).filled }
    end

    include Dry.Types(default: :nominal) # allows using Types::* in module.
    property :cool, type: Types::Params::Bool # test coercion.
  end

  # TODO: test if works, move stuff into inherit_schema!
  module AirplaysPropertyForm
    include Reform::Form::Module

    collection :airplays do
      property :station
      validation do
        params { required(:station).filled }
      end
    end
    validation do
      params { required(:airplays).filled }
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

  let(:song) { OpenStruct.new(band: OpenStruct.new(title: "Time Again")) }

  # nested form from module is present and creates accessor.
  it { assert_equal SongForm.new(song).band.title, "Time Again" }

  # methods from module get included.
  it { assert_equal SongForm.new(song).id, 1 }
  it { assert_equal SongForm.new(song).band.id, 2 }

  # validators get inherited.
  it do
    form = SongForm.new(OpenStruct.new)
    form.validate({})
    assert_equal form.errors.messages, band: ["must be filled"]
  end

  # coercion works
  it do
    form = SongForm.new(OpenStruct.new)
    form.validate(cool: "1")
    assert form.cool
  end

  # include a module into a module into a class :)
  module AlbumFormModule
    include Reform::Form::Module
    include BandPropertyForm

    property :name
    validation do
      params { required(:name).filled }
    end
  end

  class AlbumForm < TestForm
    include AlbumFormModule

    # pp heritage
    property :band, inherit: true do
      property :label
      validation do
        params { required(:label).filled }
      end
    end
  end

  it do
    form = AlbumForm.new(OpenStruct.new(band: OpenStruct.new))
    form.validate("band" => {})
    assert_equal form.errors.messages, "band.title": ["must be filled"], "band.label": ["must be filled"], name: ["must be filled"]
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
      assert_equal IncludingSongForm.new(song).id, 1
      assert_equal IncludingSongForm.new(song).title, "INSTANT MASH"
    end
  end
end
