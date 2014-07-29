require 'test_helper'
require 'representable/json'

class InheritTest < BaseTest
  class CompilationForm < AlbumForm

    puts "hits:::::::::"
    property :hit, :inherit => true do
      puts "i am evaluated"
      property :rating
      validates :title, :rating, :presence => true
    end

    puts "zo"
    puts representer_class.representable_attrs.
      get(:hit)[:extend].evaluate(nil).new(OpenStruct.new).rating

  end

  let (:album) { Album.new(nil, OpenStruct.new(:hit => OpenStruct.new()) ) }
  subject { CompilationForm.new(album) }


  # valid.
  it {
    subject.validate("hit" => {"title" => "LA Drone", "rating" => 10})
    subject.hit.title.must_equal "LA Drone"
    subject.hit.rating.must_equal 10
    subject.errors.messages.must_equal({})
  }

  it do
    puts subject.class.representer_class.representable_attrs.get(:hit)[:extend].evaluate(nil).new(album.hit).rating

    puts CompilationForm.representer_class.representable_attrs.get(:hit)[:extend].evaluate(nil).name
  end
end