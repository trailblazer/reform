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