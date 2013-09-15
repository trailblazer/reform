require_relative "../test_helper"

require "dummy/config/environment"
require "rails/test_help" # adds stuff like @routes, etc.

# require "haml"
# require "haml/template" # Thanks, Nathan!

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

class HasOneAndHasManyTest < ActionController::TestCase
  tests AlbumsController

  test "rendering 1-1 and 1-n" do
    get :new
    #puts @response.body

    assert_select "form"

    assert_select "form input" do |els|
      assert_select "[name=?]", "album[title]"
      assert_select "[name=?]", "album[songs_attributes][1][title]"
      assert_select "[name=?]", "album[songs_attributes][0][title]"
    end
  end

  test "submitting invalid form" do
    params = {
      "album"=>{"title"=>"Rio",
        "songs_attributes"=>{
          "0"=>{"name"=>""},
          "1"=>{"name"=>""}
      }}, "commit"=>"Create Album"}

    post :create, params

    assert_select "form"
    assert_select "li", "Songs title can&#39;t be blank"
  end
end