require 'test_helper'

class RepresenterOptionsTest < MiniTest::Spec
  subject { Reform::Representer::Options[] }

  # don't maintain empty excludes until fixed in representable.
  it { subject.exclude!([]).must_equal({:exclude=>[]}) }
  it { subject.include!([]).must_equal({:include=>[]}) }

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


class RepresenterTest < MiniTest::Spec
  class SongRepresenter < Reform::Representer
    property :title
    property :name
    property :genre
  end

  subject { SongRepresenter.new(Object.new) }

  describe "#fields" do
    it "returns all properties as strings" do
      SongRepresenter.fields.must_equal(["title", "name", "genre"])
    end

    # allows block.
    it do
      SongRepresenter.fields { |dfn| dfn.name =~ /n/ }.must_equal ["name", "genre"]
    end
  end
end