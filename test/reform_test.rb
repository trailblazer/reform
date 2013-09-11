require 'test_helper'

class RepresenterTest < MiniTest::Spec
  class SongRepresenter < Reform::Representer
    property :title
    property :name
  end

  let (:rpr) { SongRepresenter.new(Object.new) }

  describe "#fields" do
    it "returns all properties as strings" do
      rpr.fields.must_equal(["title", "name"])
    end
  end
end

class FieldsTest < MiniTest::Spec
  describe "#new" do
    it "accepts list of properties" do
      fields = Reform::Fields.new([:name, :title])
      fields.name.must_equal  nil
      fields.title.must_equal nil
    end

    it "accepts list of properties and values" do
      fields = Reform::Fields.new(["name", "title"], "title" => "The Body")
      fields.name.must_equal  nil
      fields.title.must_equal "The Body"
    end

    it "processes value syms" do
      skip "we don't need to test this as representer.to_hash always returns strings"
      fields = Reform::Fields.new(["name", "title"], :title => "The Body")
      fields.name.must_equal  nil
      fields.title.must_equal "The Body"
    end
  end
end

class ReformTest < ReformSpec
  let (:comp) { OpenStruct.new(:name => "Duran Duran", :title => "Rio") }

  let (:form) { SongForm.new(comp) }


  describe "::properties" do
    it do
      Class.new(Reform::Form) do
        properties [:name, :title]
      end.new(comp).to_hash.must_equal({"name"=>"Duran Duran", "title"=>"Rio"})
    end
  end

  class SongForm < Reform::Form
    property :name
    property :title

    validates :name, :presence => true
  end

  describe "(new) form with empty models" do
    let (:comp) { OpenStruct.new }

    it "returns empty fields" do
      form.title.must_equal nil
      form.name.must_equal  nil
    end

    describe "and submitted values" do
      it "returns filled-out fields" do
        form.validate("name" => "Duran Duran")

        form.title.must_equal nil
        form.name.must_equal  "Duran Duran"
      end
    end
  end

  describe "(edit) form with existing models" do
    it "returns filled-out fields" do
      form.name.must_equal  "Duran Duran"
      form.title.must_equal "Rio"
    end
  end

  describe "#validate" do
    let (:comp) { OpenStruct.new }

    it "ignores unmapped fields in input" do
      form.validate("name" => "Duran Duran", :genre => "80s")
      assert_raises NoMethodError do
        form.genre
      end
    end

    it "returns true when valid" do
      form.validate("name" => "Duran Duran").must_equal true
    end

    it "exposes input via property accessors" do
      comp.name.must_equal nil
      form.name.must_equal nil

      form.validate("name" => "Duran Duran")

      form.name.must_equal "Duran Duran"
      comp.name.must_equal nil # don't touch model, yet.
    end

    # TODO: test errors. test valid.
    describe "invalid input" do
      class ValidatingForm < Reform::Form
        property :name
        property :title

        validates :name,  :presence => true
        validates :title, :presence => true
      end
      let (:form) { ValidatingForm.new(comp) }

      it "returns false when invalid" do
        form.validate({}).must_equal false
      end

      it "populates errors" do
        form.validate({})
        form.errors.messages.must_equal({:name=>["can't be blank"], :title=>["can't be blank"]})
      end
    end

    describe "method validations" do
      it "allows accessing models" do
        form = Class.new(Reform::Form) do
          property :name
          validate "name_correct?"

          def name_correct?
            errors.add :name, "Please give me a name" if model.name.nil?
          end
        end.new(comp)

        form.validate({}).must_equal false
        form.errors.messages.must_equal({:name=>["Please give me a name"]})
      end
    end

    describe "UniquenessValidator" do
      #  ActiveRecord::Schema.define do
      #    create_table :artists do |table|
      #      table.column :name, :string
      #      table.timestamps
      #    end
      #  end
      # Artist.new(:name => "Racer X").save

      let (:form) do
        require 'reform/rails'
        Class.new(Reform::Form) do
          include Reform::Form::ActiveRecord
          model :artist

          property :name
          property :created_at

          validates_uniqueness_of :name
          validates :created_at, :presence => true # have another property to test if we mix up.
        end.
        new(Artist.new)
      end

      it "allows accessing the database" do
      end

      it "is valid when name is unique" do
        form.validate({"name" => "Paul Gilbert", "created_at" => "November 6, 1966"}).must_equal true
      end

      it "is invalid and shows error when taken" do
        form.validate({"name" => "Racer X"}).must_equal false
        form.errors.messages.must_equal({:name=>["has already been taken"], :created_at => ["can't be blank"]})
      end
    end
  end

  describe "#errors" do
    it { form.errors.must_be_kind_of Reform::Form::Errors }

    it { form.errors.messages.must_equal({}) }

    it do
      form.validate({"name"=>""})
      form.errors.messages.must_equal({:name=>["can't be blank"]})
    end
  end


  describe "#save" do
    let (:comp) { OpenStruct.new }
    let (:form) { SongForm.new(comp) }

    before { form.validate("name" => "Diesel Boy") }

    it "pushes data to models" do
      form.save

      comp.name.must_equal "Diesel Boy"
      comp.title.must_equal nil
    end

    describe "#save with block" do
      it "provides data block argument" do
        hash = {}

        form.save do |data, map|
          hash[:name]   = data.name
          hash[:title]  = data.title
        end

        hash.must_equal({:name=>"Diesel Boy", :title=>nil})
      end

      it "provides nested symbolized hash as second block argument" do
        hash = {}

        form.save do |data, map|
          hash = map
        end

        hash.must_equal({:name=>"Diesel Boy"})
      end
    end
  end


  describe "#model" do
    it { form.send(:model).must_equal comp }
  end
end
