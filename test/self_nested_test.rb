require 'test_helper'

module Reform::Form::Scalar
  def update!(object)
    model.replace(object)
  end
end

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

    puts form.inspect

    form.validate({"title" => "Teaser"})

    form.errors.messages.must_equal({:"title.model"=>["is too short (minimum is 10 characters)"]})


    # validation only kicks in when value present
    form = Form.new(song)
    form.validate({})
    form.errors.messages.must_equal({})
  end


  class ImageForm < Reform::Form
    property :image, parse_strategy: lambda { |object, args| puts "@@@"; Reform::Form.new(object) }  do
      validates :size,  numericality: { less_than: 10 }
      validates :type, inclusion: { in: "String" } # TODO: make better validators and remove AM::Validators at some point.
    end
  end

  AlbumCover = Struct.new(:image)

  # no image in params AND model.
  it do
    form = ImageForm.new(AlbumCover.new(nil))
    form.image.extend(Reform::Form::Scalar)
    form.image.instance_exec do
      def size; model.size; end
      def type; model.class.to_s; end
    end

    form.validate({})
    form.errors.messages.must_equal({})
  end

  # no image in params but in model.
  it do
    # TODO: implement validations that only run when requested (only_validate_params: true)
    form = ImageForm.new(AlbumCover.new("i don't know how i got here but i'm invalid"))
    form.image.extend(Reform::Form::Scalar)
    form.image.instance_exec do
      def size; model.size; end
      def type; model.class.to_s; end
    end

    form.validate({})
    form.errors.messages.must_equal({})
  end

  # image in params but NOT in model.
  it "xx"do
    form = ImageForm.new(AlbumCover.new(nil))
    form.image.extend(Reform::Form::Scalar)
    form.image.instance_exec do
      def size; model.size; end
      def type; model.class.to_s; end
    end

    form.validate({"image" => "I'm OK!"})
    form.errors.messages.must_equal({})
    form.image.must_equal "I'm OK!"
  end

  # OK image.
  it do
    form = ImageForm.new(AlbumCover.new("nil"))
    form.image.extend(Reform::Form::Scalar)
    form.image.instance_exec do
      def size; model.size; end
      def type; model.class.to_s; end
    end

    form.validate({"image" => "I'm OK!"})
    form.errors.messages.must_equal({})
  end

  # invalid image.
  it do
    form = ImageForm.new(AlbumCover.new("nil"))
    form.image.extend(Reform::Form::Scalar)
    form.image.instance_exec do
      def size; model.size; end
      def type; model.class.to_s; end
    end

    form.validate({"image" => "I'm too long, is that a problem?"})
    form.errors.messages.must_equal({:"image.size"=>["must be less than 10"]})
  end











  # validate test
  class BlaForm < Reform::Form
    property :image, instance: lambda { |object, args| puts "@@@"; Reform::Form.new(object) } , representable: false do

    end
  end


  it "what" do
    form = BlaForm.new(AlbumCover.new("nil"))
    form.validate("image" => {})
    form.image.model.must_equal({})
  end

end