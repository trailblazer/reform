require "test_helper"
require "reform/form/coercion"

class CoercionTest < BaseTest
  subject do
    Class.new(Reform::Form) do
      include Reform::Form::Coercion

      property :released_at, :type => DateTime

      property :hit do
        property :length, :type => Integer
        property :good,   :type => Virtus::Attribute::Boolean
      end

      property :band do
        property :label do
          property :value, :type => Float
        end
      end
    end.new(OpenStruct.new(
      :released_at => "31/03/1981",
      :hit => OpenStruct.new(:length => "312"),
      :band => Band.new(OpenStruct.new(:value => "9999.99"))
    ))
  end

  it { subject.released_at.must_be_kind_of DateTime }
  it { subject.released_at.must_equal DateTime.parse("Tue, 31 Mar 1981 00:00:00 +0000") }
  it { subject.hit.length.must_equal 312 }
  it { subject.band.label.value.must_equal 9999.99 }


  it "allows coercion in validate" do
    form = Class.new(Reform::Form) do
      include Reform::Form::Coercion

      property :id, :type => Integer
    end.new(OpenStruct.new())

    form.validate("id" => "1")
    form.id.must_equal 1
  end
end