require 'test_helper'
require 'mocha/mini_test'

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

  describe "adding multiple properties" do
    it "adds multiple fields" do
      form_class.class_eval do
        property :first_name, :last_name
      end
      form.send(:fields).methods(false).must_include(:first_name)
      form.send(:fields).methods(false).must_include(:last_name)
    end

    it "accepts multiple fields in an array (legacy syntax for .properties)" do
      form_class.class_eval do
        property [:first_name, :last_name]
      end
      form.send(:fields).methods(false).must_include(:first_name)
      form.send(:fields).methods(false).must_include(:last_name)
    end
  end

  describe '.properties' do
    it "calls .property" do
      form_class.expects(:property).with(:foo)
      form_class.class_eval do
        properties :foo
      end
    end
  end
end
