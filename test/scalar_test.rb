require 'test_helper'


class SelfNestedTest < BaseTest
  class Form < Reform::Form
    property :title  do

     end
  end

  let (:song) { Song.new("Crash And Burn") }
  it do
    Form.new(song)

  end

  it do
    form = Form.new(song)

    form.title = Class.new(Reform::Form) do
      @form_name = "ficken"
      def self.name # needed by ActiveModel::Validation and I18N.
          @form_name
        end

      validates :model, :length => {:minimum => 10}


      def update!(object)
        model.replace(object)
      end

    end.new("Crash And Burn") # gets initialized with string (or image object, or whatever).

    form.validate({"title" => "Teaser"})

    form.errors.messages.must_equal({:"title.model"=>["is too short (minimum is 10 characters)"]})


    # validation only kicks in when value present
    form = Form.new(song)
    form.validate({})
    form.errors.messages.must_equal({})
  end


  class ImageForm < Reform::Form
    # property :image, populate_if_empty: lambda { |object, args| object }  do
    property :image, :scalar => true do
      validates :size,  numericality: { less_than: 10 }
      validates :length, numericality: { greater_than: 1 } # TODO: make better validators and remove AM::Validators at some point.

      # FIXME: does that only work with representable 2.0?
      # def size; model.size; end
      # def type; model.class.to_s; end
    end
  end

  AlbumCover = Struct.new(:image) do
    include Saveable
  end

  # no image in params AND model.
  it do
    form = ImageForm.new(AlbumCover.new(nil))


    form.validate({})
    form.errors.messages.must_equal({})
  end

  # no image in params but in model.
  it do
    skip

    # TODO: implement validations that only run when requested (only_validate_params: true)
    form = ImageForm.new(AlbumCover.new("i don't know how i got here but i'm invalid"))


    form.validate({})
    form.errors.messages.must_equal({})
  end

  # image in params but NOT in model.
  it do
    form = ImageForm.new(AlbumCover.new(nil))

    form.validate({"image" => "I'm OK!"})
    puts form.inspect
    form.errors.messages.must_equal({})
    form.image.scalar.must_equal "I'm OK!"
  end

  # OK image, image existent.
  it "hello" do
    form = ImageForm.new(AlbumCover.new("nil"))

    form.image.model.must_equal "nil"

    form.validate({"image" => "I'm OK!"})
    form.errors.messages.must_equal({})
  end

  # invalid image, image existent.
  it "xx"do
    form = ImageForm.new(AlbumCover.new("nil"))

    form.validate({"image" => "I'm too long, is that a problem?"})
    form.errors.messages.must_equal({:"image.size"=>["must be less than 10"]})
  end



  # validate string only if it's in params.
  class StringForm < Reform::Form
    property :image, :scalar => true do # creates "empty" form
      validates :length => {:minimum => 10}
    end
  end


  # validates when present.
  # invalid
  it do
    form = StringForm.new(AlbumCover.new(nil))
    form.validate("image" => "0x123").must_equal false
    form.image.scalar.must_equal("0x123")
    # TODO: errors, save

    form.errors.messages.must_equal({:"image.scalar"=>["is too short (minimum is 10 characters)"]})
  end

  # valid
  it "xxx" do
    cover = AlbumCover.new(nil)

    form = StringForm.new(cover)
    form.validate("image" => "0x123456789").must_equal true

    form.image.scalar.must_equal("0x123456789")
    cover.image.must_equal nil

    # errors
    form.errors.messages.must_equal({})

    # sync
    form.sync
    form.image.scalar.must_equal("0x123456789")
    cover.image.must_equal "0x123456789" # that already writes it back.

    # save
    form.save
    cover.image.must_equal "0x123456789" # #save writes back to model.

    form.save do |hash|
      hash.must_equal("image"=>"0x123456789")
    end
  end

  # does not validate when absent (that's the whole point of this directive).
  it do
    form = StringForm.new(AlbumCover.new(nil))
    form.validate({}).must_equal true
  end

  # DISCUSS: when AlbumCover.new("Hello").validate({}), does that fail?
end