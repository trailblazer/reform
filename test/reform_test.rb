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

class WithOptionsTest < MiniTest::Spec
  subject { Reform::Representer::WithOptions::Options.new }

  it { subject.must_equal({}) }
  it { subject.exclude!([:id, :title]).must_equal(:exclude => [:id, :title])   }
  it do
    subject.exclude!([:id, :title])
    subject.exclude!([:id, :name])
    subject.must_equal(:exclude => [:id, :title, :id, :name])
  end
  it { subject.include!([:id, :title]).must_equal(:include => [:id, :title]) }
end

class FieldsTest < MiniTest::Spec
  describe "#new" do
    it "accepts list of properties" do
      fields = Reform::Contract::Fields.new([:name, :title])
      fields.name.must_equal  nil
      fields.title.must_equal nil
    end

    it "accepts list of properties and values" do
      fields = Reform::Contract::Fields.new(["name", "title"], "title" => "The Body")
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


  describe "::property" do
    it "doesn't allow reserved names" do
      assert_raises RuntimeError do
        Class.new(Reform::Form) do
          property :model
        end
      end
    end
  end


  describe "::properties" do
    subject do
      Class.new(Reform::Form) do
        properties [:name, :title]
      end.new(comp)
    end

    it { subject.name.must_equal "Duran Duran" }
    it { subject.title.must_equal "Rio" }
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
      form.validate("name" => "Duran Duran")

      form.name.must_equal "Duran Duran"
    end

    it "doesn't change model properties" do
      form.validate("name" => "Duran Duran")

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

  end

  describe "#errors" do
    before { form.validate({})}

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
      it "Deprecated: provides data block argument" do # TODO: remove in 1.1.
        hash = {}

        form.save do |data, map|
          hash[:name]   = data.name
          hash[:title]  = data.title
        end

        hash.must_equal({:name=>"Diesel Boy", :title=>nil})
      end

      it "Deprecated: provides nested symbolized hash as second block argument" do # TODO: remove in 1.1.
        hash = {}

        form.save do |data, map|
          hash = map
        end

        hash.must_equal({"name"=>"Diesel Boy"})
      end

      it do
        hash = {}

        form.save do |map|
          hash = map
        end

        hash.must_equal({"name"=>"Diesel Boy"})
      end
    end
  end


  describe "#model" do
    it { form.model.must_equal comp }
  end


  describe "inheritance" do
    class HitForm < SongForm
      property :position
      validates :position, :presence => true
    end

    let (:form) { HitForm.new(OpenStruct.new()) }
    it do
      form.validate({"title" => "The Body"})
      form.title.must_equal "The Body"
      form.position.must_equal nil
      form.errors.messages.must_equal({:name=>["can't be blank"], :position=>["can't be blank"]})
    end
  end

  describe "#column_for_attribute" do
    let (:model) { Artist.new }
    let (:klass) do
      require 'reform/active_record'
      Class.new(Reform::Form) do
        include Reform::Form::ActiveRecord
        model :artist

        property :name
      end
    end
    let (:form) { klass.new(model) }

    it 'should delegate to the model' do
      Calls = []
      def model.column_for_attribute(name)
        Calls << :column_for_attribute
      end

      form.column_for_attribute(:name)
      Calls.must_include :column_for_attribute
    end
  end
end


class EmptyAttributesTest < MiniTest::Spec
  Credentials = Struct.new(:password)

  class PasswordForm < Reform::Form
    property :password
    property :password_confirmation, :empty => true
  end

  let (:cred) { Credentials.new }
  let (:form) { PasswordForm.new(cred) }

  before { form.validate("password" => "123", "password_confirmation" => "321") }

  it {
    form.password.must_equal "123"
    form.password_confirmation.must_equal "321"

    form.sync
    cred.password.must_equal "123"

    hash = {}
    form.save do |nested|
      hash = nested
    end

    hash.must_equal("password"=> "123", "password_confirmation" => "321")
  }
end

class ReadonlyAttributesTest < MiniTest::Spec
  Location = Struct.new(:country)

  class LocationForm < Reform::Form
    property :country, :virtual => true # read_only: true
  end

  let (:loc) { Location.new("Australia") }
  let (:form) { LocationForm.new(loc) }

  it { form.country.must_equal "Australia" }
  it do
    form.validate("country" => "Germany") # this usually won't change when submitting.
    form.country.must_equal "Germany"


    form.sync
    loc.country.must_equal "Australia" # the writer wasn't called.

    hash = {}
    form.save do |nested|
      hash = nested
    end

    hash.must_equal("country"=> "Germany")
  end
end


class OverridingAccessorsTest < BaseTest
  class SongForm < Reform::Form
    property :title

    def title=(v) # used in #validate.
      super v*2
    end

    def title # used in #sync.
      super.downcase
    end
  end

  let (:song) { Song.new("Pray") }
  subject { SongForm.new(song) }

  # override reader for presentation.
  it { subject.title.must_equal "pray" }


  describe "#save" do
    before { subject.validate("title" => "Hey Little World") }

    # reader always used
    it { subject.title.must_equal "hey little worldhey little world" }

    # the reader is not used when saving/syncing.
    it do
      subject.save do |hash|
        hash["title"].must_equal "Hey Little WorldHey Little World"
      end
    end

    # no reader or writer used when saving/syncing.
    it do
      song.extend(Saveable)
      subject.save
      song.title.must_equal "Hey Little WorldHey Little World"
    end
  end
end


class MethodInFormTest < MiniTest::Spec
  class AlbumForm < Reform::Form
    property :title

    def title
      "The Suffer And The Witness"
    end

    property :hit do
      property :title

      def title
        "Drones"
      end
    end
  end

  # methods can be used instead of created accessors.
  subject { AlbumForm.new(OpenStruct.new(:hit => OpenStruct.new)) }
  it { subject.title.must_equal "The Suffer And The Witness" }
  it { subject.hit.title.must_equal "Drones" }
end
