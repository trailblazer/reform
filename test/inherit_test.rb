require 'test_helper'
require 'representable/json'

class InheritTest < BaseTest
  puts
  puts
  class AlbumForm < Reform::Form
    property :title, deserializer: {instance: "Instance"} # allow direct configuration of :deserializer.

    property :hit, populator: "Populator" do
      property :title
    end

    collection :songs, populate_if_empty: lambda {}, skip_if: :all_blank do
      property :title
    end

    property :artist, populate_if_empty: lambda {} do

    end
  end

  puts
  puts "inherit"

  class CompilationForm < AlbumForm

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
    # don't overwrite direct deserializer: {} configuration.
    AlbumForm.options_for(:title)[:deserializer][:instance].must_equal "Instance"
    AlbumForm.options_for(:hit)[:deserializer][:instance].inspect.must_match /Reform::Form::Populator:.+ @user_proc="Populator"/
    # AlbumForm.options_for(:hit)[:deserializer][:instance].inspect.must_be_instance_with Reform::Form::Populator, user_proc: "Populator"


    AlbumForm.options_for(:songs)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty
    AlbumForm.options_for(:songs)[:deserializer][:skip_parse].must_be_instance_of Reform::Form::Validate::Skip::AllBlank

    AlbumForm.options_for(:artist)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty


    # pp CompilationForm.options_for(:songs)
    CompilationForm.options_for(:songs)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty

    CompilationForm.options_for(:artist)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::IfEmpty

    # completely overwrite inherited.
    CompilationForm.options_for(:hit)[:deserializer][:instance].must_be_instance_of Reform::Form::Populator::Sync # reset to default.
    CompilationForm.options_for(:hit)[:deserializer][:skip_parse].must_equal "SkipParse"
  end
end


# require 'reform/form/coercion'
# class ModuleInclusionTest < MiniTest::Spec
#   module BandPropertyForm
#     include Reform::Form::Module

#     property :band do
#       property :title

#       validates :title, :presence => true

#       def id # gets mixed into Form, too.
#         2
#       end
#     end

#     def id # gets mixed into Form, too.
#       1
#     end

#     validates :band, :presence => true

#     property :cool, type: Virtus::Attribute::Boolean # test coercion.
#   end

#   # TODO: test if works, move stuff into inherit_schema!
#   module AirplaysPropertyForm
#     include Reform::Form::Module

#     collection :airplays do
#       property :station
#       validates :station, :presence => true
#     end
#     validates :airplays, :presence => true
#   end


#   # test:
#   # by including BandPropertyForm into multiple classes we assure that options hashes don't get messed up by AM:V.
#   class HitForm < Reform::Form
#     include BandPropertyForm
#   end

#   class SongForm < Reform::Form
#     property :title

#     include BandPropertyForm
#   end


#   let (:song) { OpenStruct.new(:band => OpenStruct.new(:title => "Time Again")) }

#   # nested form from module is present and creates accessor.
#   it { SongForm.new(song).band.title.must_equal "Time Again" }

#   # methods from module get included.
#   it { SongForm.new(song).id.must_equal 1 }
#   it { SongForm.new(song).band.id.must_equal 2 }

#   # validators get inherited.
#   it do
#     form = SongForm.new(OpenStruct.new)
#     form.validate({})
#     form.errors.messages.must_equal({:band=>["can't be blank"]})
#   end

#   # coercion works
#   it do
#     form = SongForm.new(OpenStruct.new)
#     form.validate({:cool => "1"})
#     form.cool.must_equal true
#   end


#   # include a module into a module into a class :)
#   module AlbumFormModule
#     include Reform::Form::Module
#     include BandPropertyForm

#     property :name
#     validates :name, :presence => true
#   end

#   class AlbumForm < Reform::Form
#     include AlbumFormModule

#     property :band, :inherit => true do
#       property :label
#       validates :label, :presence => true
#     end
#   end
#   # puts "......"+ AlbumForm.representer_class.representable_attrs.get(:band).inspect

#   it do
#     form = AlbumForm.new(OpenStruct.new(:band => OpenStruct.new))
#     form.validate({"band" => {}})
#     form.errors.messages.must_equal({:"band.title"=>["can't be blank"], :"band.label"=>["can't be blank"], :name=>["can't be blank"]})
#   end


#   # including representer into form
#   module GenericRepresenter
#     include Representable

#     property :title
#     property :manager do
#       property :title
#     end
#   end

#   class LabelForm < Reform::Form
#     property :location

#     include GenericRepresenter
#     validates :title, :presence => true
#     property :manager, :inherit => true do
#       validates :title, :presence => true
#     end
#   end
#     puts "......"+ LabelForm.representer_class.representable_attrs.get(:title).inspect


#   it do
#     form = LabelForm.new(OpenStruct.new(:manager => OpenStruct.new))
#     form.validate({"manager" => {}, "title"=>""}) # it's important to pass both nested and scalar here!
#     form.errors.messages.must_equal(:title=>["can't be blank"], :"manager.title"=>["can't be blank"], )
#   end
# end