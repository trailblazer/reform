require 'test_helper'

class ReformTest < MiniTest::Spec
  describe "what" do
    it "passes form data as block argument" do
      class StudentProfileComposition < Form::Mapper
        attribute :email, on: :student
        #attribute :grade, on: :profile
      end

      class SongForm < Form

      end

      SongForm.new(StudentProfileComposition.new(:student => OpenStruct.new(:email => "bla"))).save do |data|
        puts data.student.inspect
        puts data.student.email.inspect
      end
    end
  end
end