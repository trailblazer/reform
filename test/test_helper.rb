require 'reform'
require 'minitest/autorun'

class ReformSpec < MiniTest::Spec
  let (:duran)  { OpenStruct.new(:name => "Duran Duran") }
  let (:rio)    { OpenStruct.new(:title => "Rio") }
end

require 'active_record'
class Artist < ActiveRecord::Base
end
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "#{Dir.pwd}/database.sqlite3"
)

#Artist.delete_all

class BaseTest < MiniTest::Spec
  class AlbumForm < Reform::Form
    property :title

    property :hit do
      property :title
    end

    collection :songs do
      property :title
    end
  end

  Song  = Struct.new(:title)
  Album = Struct.new(:title, :hit, :songs, :band)
  Band  = Struct.new(:label)
  Label = Struct.new(:name)


  let (:hit) { Song.new("Roxanne") }
end