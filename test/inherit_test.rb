require 'test_helper'
require 'representable/json'

class InheritTest < BaseTest
  class AlbumForm < Reform::Form
    property :title, deserializer: {instance: "Instance"}, skip_if: "skip_if in AlbumForm" # allow direct configuration of :deserializer.
    # puts "[#{options_for(:title)[:deserializer].object_id}] ALB@@@@@ #{options_for(:title)[:deserializer].inspect}"

    property :hit, populator: "Populator" do
      property :title
    end

    collection :songs, populate_if_empty: lambda {}, skip_if: :all_blank do
      property :title
    end

    property :artist, populate_if_empty: lambda {} do

      def artist_id
        1
      end
    end
  end

  puts
  puts "inherit"

  class CompilationForm < AlbumForm
    property :title, inherit: true, skip_if: "skip_if from CompilationForm"
    puts "[#{options_for(:title)[:deserializer].object_id}] COM@@@@@ #{options_for(:title)[:deserializer].inspect}"
    # property :hit, :inherit => true do
    #   property :rating
    #   validates :title, :rating, :presence => true
    # end

    # puts representer_class.representable_attrs.
    #   get(:hit)[:extend].evaluate(nil).new(OpenStruct.new).rating

    # NO collection here, this is entirely inherited.
    # collection :songs, ..

    property :artist, inherit: true do # inherit everything, but explicitely.
    end

    # completely override.
    property :hit, skip_if: "SkipParse" do
    end

    # override partly.
  end

  let (:album) { Album.new(nil, OpenStruct.new(:hit => OpenStruct.new()) ) }
  subject { CompilationForm.new(album) }


  # valid.
  # it {
  #   subject.validate("hit" => {"title" => "LA Drone", "rating" => 10})
  #   subject.hit.title.must_equal "LA Drone"
  #   subject.hit.rating.must_equal 10
  #   subject.errors.messages.must_equal({})
  # }

  # it do
  #   subject.validate({})
  #   subject.hit.title.must_equal nil
  #   subject.hit.rating.must_equal nil
  #   subject.errors.messages.must_equal({:"hit.title"=>["can't be blank"], :"hit.rating"=>["can't be blank"]})
  # end

require "pp"

  it "xxx" do
    # sub hashes like :deserializer must be properly cloned when inheriting.
    AlbumForm.options_for(:title)[:deserializer].object_id.wont_equal CompilationForm.options_for(:title)[:deserializer].object_id

    # don't overwrite direct deserializer: {} configuration.
    AlbumForm.options_for(:title)[:deserializer][:instance].must_equal "Instance"
    AlbumForm.options_for(:title)[:deserializer][:skip_parse].must_equal "skip_if in AlbumForm"

    AlbumForm.options_for(:hit)[:deserializer][:instance].inspect.must_match /Reform::Form::Populator:.+ @user_proc="Populator"/
    # AlbumForm.options_for(:hit)[:deserializer][:instance].inspect.must_be_instance_with Reform::Form::Populator, user_proc: "Populator"


    AlbumForm.options_for(:songs)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty
    AlbumForm.options_for(:songs)[:deserializer][:skip_parse].must_be_instance_of Reform::Form::Validate::Skip::AllBlank

    AlbumForm.options_for(:artist)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty



    CompilationForm.options_for(:title)[:deserializer][:skip_parse].must_equal "skip_if from CompilationForm"
    # pp CompilationForm.options_for(:songs)
    CompilationForm.options_for(:songs)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty

    CompilationForm.options_for(:artist)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty

    # completely overwrite inherited.
    CompilationForm.options_for(:hit)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::Sync # reset to default.
    CompilationForm.options_for(:hit)[:deserializer][:skip_parse].must_equal "SkipParse"


    # inherit: true with block will still inherit the original class.
    AlbumForm.new(OpenStruct.new(artist: OpenStruct.new)).artist.artist_id.must_equal 1
    CompilationForm.new(OpenStruct.new(artist: OpenStruct.new)).artist.artist_id.must_equal 1
  end
end