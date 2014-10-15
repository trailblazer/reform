require 'test_helper'

class RepresenterOptionsTest < MiniTest::Spec
  subject { Reform::Representer::Options[] }

  # don't maintain empty excludes until fixed in representable.
  it { subject.exclude!([]).must_equal({}) }
  it { subject.include!([]).must_equal({}) }

  it { subject.exclude!([:title, :id]).must_equal({exclude: [:title, :id]}) }
  it { subject.include!([:title, :id]).must_equal({include: [:title, :id]}) }


  module Representer
    include Representable::Hash
    property :title
    property :genre
    property :id
  end

  it "representable" do
    song = OpenStruct.new(title: "Title", genre: "Punk", id: 1)
    puts Representer.prepare(song).to_hash(include: [:genre, :id], exclude: [:id]).inspect
  end
end