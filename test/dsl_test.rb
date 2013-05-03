require 'test_helper'

class DslTest < MiniTest::Spec
  class SongForm < Reform::Form
    include DSL

    property :title,  on: :song
    property :name,   on: :artist

    validates :name, :title, presence: true
  end

  let (:form) { SongForm.new(:song => OpenStruct.new(:title => "Rio"), :artist => OpenStruct.new()) }

  it "what" do
    form.validate("title" => "Greyhound").must_equal false
  end
end