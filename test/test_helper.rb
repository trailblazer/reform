require 'reform'
require 'minitest/autorun'

require "dummy/config/environment"

class ReformSpec < MiniTest::Spec
  let (:duran)  { OpenStruct.new(:name => "Duran Duran") }
  let (:rio)    { OpenStruct.new(:title => "Rio") }
end
