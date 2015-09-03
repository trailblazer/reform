require 'test_helper'

class ReformTest < ReformSpec
  describe "Date" do
    Person = Struct.new(:date_of_birth)
    let (:form) { DateOfBirthForm.new(Person.new) }

    class DateOfBirthForm < Reform::Form
      feature Reform::Form::ActiveModel::FormBuilderMethods
      feature Reform::Form::MultiParameterAttributes
      property :date_of_birth, type: Date, :multi_params => true
    end

    it "munges multi-param date fields into a valid Date attribute" do
      date_of_birth_params = { "date_of_birth(1i)"=>"1950", "date_of_birth(2i)"=>"1", "date_of_birth(3i)"=>"1" }
      form.validate(date_of_birth_params)
      form.date_of_birth.must_equal Date.civil(1950, 1, 1)
    end

    it "handles invalid Time input" do
      date_of_birth_params = { "date_of_birth(1i)"=>"1950", "date_of_birth(2i)"=>"99", "date_of_birth(3i)"=>"1" }
      form.validate(date_of_birth_params)
      form.date_of_birth.must_equal nil
    end
  end

  describe "DateTime" do
    Party = Struct.new(:start_time)
    let (:form) { PartyForm.new(Party.new) }

    class PartyForm < Reform::Form
      feature Reform::Form::ActiveModel::FormBuilderMethods
      feature Reform::Form::MultiParameterAttributes
      property :start_time, type: DateTime, :multi_params => true
    end

    it "munges multi-param date and time fields into a valid Time attribute" do
      start_time_params = { "start_time(1i)"=>"2000", "start_time(2i)"=>"1", "start_time(3i)"=>"1", "start_time(4i)"=>"12", "start_time(5i)"=>"00" }
      time_format = "%Y-%m-%d %H:%M"
      form.validate(start_time_params)
      form.start_time.strftime(time_format).must_equal DateTime.strptime("2000-01-01 12:00", time_format)
    end

    it "handles invalid Time input" do
      start_time_params = { "start_time(1i)"=>"2000", "start_time(2i)"=>"99", "start_time(3i)"=>"1", "start_time(4i)"=>"12", "start_time(5i)"=>"00" }
      form.validate(start_time_params)
      form.start_time.must_equal nil
    end
  end
end
