require_relative "../test_helper"

require "dummy/config/environment"
require "rails/test_help" # adds stuff like @routes, etc.

require "haml"
require "haml/template" # Thanks, Nathan!

#ActiveRecord::Schema.define do
  # create_table :artists do |table|
  #   table.column :name, :string
  #   table.timestamps
  # end

#   create_table :songs do |table|
#     table.column :title, :string
#     table.column :album_id, :integer
#   end

#   create_table :albums do |table|
#     table.column :title, :string
#   end
# end

class RailsTest < ActionController::TestCase
  tests MusicianController

  # test "bla" do
  #   get :index
  # end

  # test "rendering 1-n" do
  #   get :album_new
  # end
end

class HasOneAndHasManyTest < ActionController::TestCase
  tests AlbumsController

  test "rendering 1-1 and 1-n" do
    get :new
  end
end