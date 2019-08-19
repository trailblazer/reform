require "test_helper"

class ErrorsTest < MiniTest::Spec
  class AlbumForm < TestForm
    property :title

    property :hit do
      property :title
      validation do
        required(:title).filled
      end
    end

    collection :songs do
      property :title
      validation do
        required(:title).filled
      end
    end

    property :band do # yepp, people do crazy stuff like that.
      property :name
      property :label do
        property :name
        validation do
          required(:name).filled
        end
      end
      # TODO: make band a required object.

      validation do
        configure do
          config.messages_file = "test/fixtures/dry_error_messages.yml"

          def good_musical_taste?(value)
            value != "Nickelback"
          end
        end

        required(:name).filled(:good_musical_taste?)
      end
      # validate :music_taste_ok?

    # private
    #   def music_taste_ok?
    #     errors.add(:base, "You are a bad person") if name == "Nickelback"
    #   end
    end

    validation do
      required(:title).filled
    end
  end

  let (:album) do
    OpenStruct.new(
      :title  => "Blackhawks Over Los Angeles",
      :hit    => song,
      :songs  => songs, # TODO: document this requirement,

      :band => Struct.new(:name, :label).new("Epitaph", OpenStruct.new),
    )
  end
  let (:song)  { OpenStruct.new(:title => "Downtown") }
  let (:songs) { [song=OpenStruct.new(:title => "Calling"), song] }
  let (:form)  { AlbumForm.new(album) }


  describe "incorrect #validate" do
    before { form.validate(
      "hit"   =>{"title" => ""},
      "title" => "",
      "songs" => [{"title" => ""}, {"title" => ""}]) } # FIXME: what happens if item must be filled?

    it do
      form.errors.messages.must_equal({
        :title  => ["must be filled"],
        :"hit.title"=>["must be filled"],
        :"songs.title"=>["must be filled"],
        :"band.label.name"=>["must be filled"]
      })
    end

    it do
      #form.errors.must_equal({:title  => ["must be filled"]})
      # TODO: this should only contain local errors?
    end

    # nested forms keep their own Errors:
    it { form.hit.errors.messages.must_equal({:title=>["must be filled"]}) }
    it { form.songs[0].errors.messages.must_equal({:title=>["must be filled"]}) }

    it do
      form.errors.messages.must_equal({
        :title        => ["must be filled"],
        :"hit.title"  => ["must be filled"],
        :"songs.title"=> ["must be filled"],
        :"band.label.name"=>["must be filled"]
      })
      form.errors.count.must_equal(4)
    end
  end


  describe "#validate with main form invalid" do
    it do
      form.validate("title"=>"", "band"=>{"label"=>{:name => "Fat Wreck"}}).must_equal false
      form.errors.messages.must_equal({:title=>["must be filled"]})
      form.errors.count.must_equal(1)
    end
  end


  describe "#validate with middle nested form invalid" do
    before { @result = form.validate("hit"=>{"title" => ""}, "band"=>{"label"=>{:name => "Fat Wreck"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"hit.title"=>["must be filled"]}) }
    it { form.errors.count.must_equal(1) }
  end


  describe "#validate with collection form invalid" do
    before { @result = form.validate("songs"=>[{"title" => ""}], "band"=>{"label"=>{:name => "Fat Wreck"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"songs.title"=>["must be filled"]}) }
    it { form.errors.count.must_equal(1) }
  end


  describe "#validate with collection and 2-level-nested invalid" do
    before { @result = form.validate("songs"=>[{"title" => ""}], "band" => {"label" => {}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal({:"songs.title"=>["must be filled"], :"band.label.name"=>["must be filled"]}) }
    it { form.errors.count.must_equal(2) }
  end

  describe "#validate with nested form using :base invalid" do
    it do
      result = form.validate("songs"=>[{"title" => "Someday"}], "band" => {"name" => "Nickelback", "label" => {"name" => "Roadrunner Records"}})
      result.must_equal false
      form.errors.messages.must_equal({:"band.name"=>["you're a bad person"]})
      form.errors.count.must_equal(1)
    end
  end

  describe "correct #validate" do
    before { @result = form.validate(
      "hit"   => {"title" => "Sacrifice"},
      "title" => "Second Heat",
      "songs" => [{"title"=>"Heart Of A Lion"}],
      "band"  => {"label"=>{:name => "Fat Wreck"}}
      ) }

    it { @result.must_equal true }
    it { form.hit.title.must_equal "Sacrifice" }
    it { form.title.must_equal "Second Heat" }
    it { form.songs.first.title.must_equal "Heart Of A Lion" }
    it do
      form.errors.count.must_equal(0)
      form.errors.empty?.must_equal(true)
    end
  end


  describe "Errors#to_s" do
    before { form.validate("songs"=>[{"title" => ""}], "band" => {"label" => {}}) }

    # to_s is aliased to messages
    it { form.errors.to_s.must_equal "{:\"songs.title\"=>[\"must be filled\"], :\"band.label.name\"=>[\"must be filled\"]}" }
  end
end
