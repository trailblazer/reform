require 'test_helper'

class ActiveRecordTest < MiniTest::Spec
  let (:form) do
    require 'reform/active_record'
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

  it { form.class.i18n_scope.must_equal :activerecord }

  describe "UniquenessValidator" do
    #  ActiveRecord::Schema.define do
    #    create_table :artists do |table|
    #      table.column :name, :string
    #      table.timestamps
    #    end
    #  end
    # Artist.new(:name => "Racer X").save

    it "allows accessing the database" do
    end

    it "is valid when name is unique" do
      form.validate({"name" => "Paul Gilbert", "created_at" => "November 6, 1966"}).must_equal true
    end

    it "is invalid and shows error when taken" do
      Artist.create(:name => "Racer X")

      form.validate({"name" => "Racer X"}).must_equal false
      form.errors.messages.must_equal({:name=>["has already been taken"], :created_at => ["can't be blank"]})
    end
  end

  describe "#save" do
    # TODO: test 1-n?
    it "calls AR#save" do
      Artist.delete_all
      form.validate("name" => "Bad Religion")
      form.save
      Artist.where(:name => "Bad Religion").size.must_equal 1
    end
  end
end