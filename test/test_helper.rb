require 'reform'
require 'minitest/autorun'

class ReformSpec < MiniTest::Spec
  let (:duran)  { OpenStruct.new(:name => "Duran Duran") }
  let (:rio)    { OpenStruct.new(:title => "Rio") }
end

require 'active_record'
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "#{Dir.pwd}/database.sqlite3"
)

class Artist < ActiveRecord::Base
end
class Album < ActiveRecord::Base
  has_many :songs #, autosave: true
end
class Song < ActiveRecord::Base
  belongs_to :album
end

[Artist, Album, Song].each(&:delete_all)
