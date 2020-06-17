require "test_helper"
require "representable/json"

class InheritTest < BaseTest
  Populator = Reform::Form::Populator

  class SkipParse
    include Uber::Callable
    def call(*_args)
      false
    end
  end

  class AlbumForm < TestForm
    property :title, deserializer: {instance: "Instance"}, skip_if: "skip_if in AlbumForm" # allow direct configuration of :deserializer.

    property :hit, populate_if_empty: ->(*) { Song.new } do
      property :title
      validation do
        params { required(:title).filled }
      end
    end

    collection :songs, populate_if_empty: -> {}, skip_if: :all_blank do
      property :title
    end

    property :band, populate_if_empty: -> {} do
      def band_id
        1
      end
    end
  end

  class CompilationForm < AlbumForm
    property :title, inherit: true, skip_if: "skip_if from CompilationForm"
    property :hit, inherit: true, populate_if_empty: ->(*) { Song.new }, skip_if: SkipParse.new do
      property :rating
      validation do
        params { required(:rating).filled }
      end
    end

    # NO collection here, this is entirely inherited.

    property :band, inherit: true do # inherit everything, but explicitely.
    end
  end

  let(:album) { Album.new(nil, Song.new, [], Band.new) }
  subject { CompilationForm.new(album) }

  it do
    subject.validate("hit" => {"title" => "LA Drone", "rating" => 10})
    _(subject.hit.title).must_equal "LA Drone"
    _(subject.hit.rating).must_equal 10
    _(subject.errors.messages).must_equal({})
  end

  it do
    subject.validate({})
    assert_nil subject.model.hit.title
    assert_nil subject.model.hit.rating
    _(subject.errors.messages).must_equal("hit.title": ["must be filled"], "hit.rating": ["must be filled"])
  end

  it "xxx" do
    # sub hashes like :deserializer must be properly cloned when inheriting.
    _(AlbumForm.options_for(:title)[:deserializer].object_id).wont_equal CompilationForm.options_for(:title)[:deserializer].object_id

    # don't overwrite direct deserializer: {} configuration.
    _(AlbumForm.options_for(:title)[:internal_populator]).must_be_instance_of Reform::Form::Populator::Sync
    _(AlbumForm.options_for(:title)[:deserializer][:skip_parse]).must_equal "skip_if in AlbumForm"

    # AlbumForm.options_for(:hit)[:internal_populator].inspect.must_match /Reform::Form::Populator:.+ @user_proc="Populator"/
    # AlbumForm.options_for(:hit)[:deserializer][:instance].inspect.must_be_instance_with Reform::Form::Populator, user_proc: "Populator"

    _(AlbumForm.options_for(:songs)[:internal_populator]).must_be_instance_of Reform::Form::Populator::IfEmpty
    _(AlbumForm.options_for(:songs)[:deserializer][:skip_parse]).must_be_instance_of Reform::Form::Validate::Skip::AllBlank

    _(AlbumForm.options_for(:band)[:internal_populator]).must_be_instance_of Reform::Form::Populator::IfEmpty

    _(CompilationForm.options_for(:title)[:deserializer][:skip_parse]).must_equal "skip_if from CompilationForm"
    # pp CompilationForm.options_for(:songs)
    _(CompilationForm.options_for(:songs)[:internal_populator]).must_be_instance_of Reform::Form::Populator::IfEmpty

    _(CompilationForm.options_for(:band)[:internal_populator]).must_be_instance_of Reform::Form::Populator::IfEmpty

    # completely overwrite inherited.
    _(CompilationForm.options_for(:hit)[:deserializer][:skip_parse]).must_be_instance_of SkipParse

    # inherit: true with block will still inherit the original class.
    _(AlbumForm.new(OpenStruct.new(band: OpenStruct.new)).band.band_id).must_equal 1
    _(CompilationForm.new(OpenStruct.new(band: OpenStruct.new)).band.band_id).must_equal 1
  end

  class CDForm < AlbumForm
    # override :band's original populate_if_empty but with :inherit.
    property :band, inherit: true, populator: "CD Populator" do

    end
  end

  it { _(CDForm.options_for(:band)[:internal_populator].instance_variable_get(:@user_proc)).must_equal "CD Populator" }
end
