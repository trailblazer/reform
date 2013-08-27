require_relative "../test_helper"

require "dummy/config/environment"
require "rails/test_help" # adds stuff like @routes, etc.

 #  ActiveRecord::Schema.define do
      #    create_table :artists do |table|
      #      table.column :name, :string
      #      table.timestamps
      #    end
      #  end

class RailsTest < ActionController::TestCase
  tests MusicianController

  test "bla" do
    get :index
  end
end