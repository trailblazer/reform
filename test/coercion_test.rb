require "test_helper"
require "reform/form/coercion"

class CoercionTest < MiniTest::Spec
  it "allows coercion" do
    form = Class.new(Reform::Form) do
      include Reform::Form::Coercion

      property :written_at, :type => DateTime
    end.new(OpenStruct.new(:written_at => "31/03/1981"))

    form.written_at.must_be_kind_of DateTime
    form.written_at.must_equal DateTime.parse("Tue, 31 Mar 1981 00:00:00 +0000")
  end

  it "allows coercion in validate" do
    form = Class.new(Reform::Form) do
      include Reform::Form::Coercion

      property :id, :type => Integer
    end.new(OpenStruct.new())

    form.validate("id" => "1")
    form.to_hash.must_equal("id" => 1)
  end
end