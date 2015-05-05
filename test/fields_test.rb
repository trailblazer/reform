require 'test_helper'

class FieldsTest < MiniTest::Spec
  describe "#new" do
    it "accepts list of properties" do
      fields = Reform::Contract::Fields.new([:name, :title])
      fields.name.must_equal  nil
      fields.title.must_equal nil

      fields.title= "Planet X"
      fields.title.must_equal "Planet X"
    end
  end
end