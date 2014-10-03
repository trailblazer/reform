require 'test_helper'

describe Reform::Form do
  let(:form_class) do
    Class.new(Reform::Form) do
      include Reform::Form::ActiveModel::FormBuilderMethods
      def self.name
        'TestForm'
      end
    end
  end
  let(:form) { form_class.new(OpenStruct.new) }

  describe "inline validation definition" do
    before do
      form_class.class_eval do
        property :title, validates: {presence: true}
      end
    end

    describe "with blank title" do
      it "fails validation" do
        form.validate(title: "").must_equal false
      end
    end

    describe "with title" do
      it "passes validation" do
        form.validate(title: "yeah").must_equal true
      end
    end
  end
end
