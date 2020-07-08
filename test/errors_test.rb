require "test_helper"

class ErrorsTest < MiniTest::Spec
  class AlbumForm < TestForm
    property :title
    validation do
      params { required(:title).filled }
    end

    property :artists, default: []
    property :producer do
      property :name
    end

    property :hit do
      property :title
      validation do
        params { required(:title).filled }
      end
    end

    collection :songs do
      property :title
      validation do
        params { required(:title).filled }
      end
    end

    property :band do # yepp, people do crazy stuff like that.
      property :name
      property :label do
        property :name
        validation do
          params { required(:name).filled }
        end
      end
      # TODO: make band a required object.

      validation do
        config.messages.load_paths << "test/fixtures/dry_error_messages.yml"

        params { required(:name).filled }

        rule(:name) { key.failure(:good_musical_taste?) if value == "Nickelback" }
      end
    end

    validation do
      params do
        required(:title).filled
        required(:artists).each(:str?)
        required(:producer).hash do
          required(:name).filled
        end
      end
    end
  end

  let(:album_title) { "Blackhawks Over Los Angeles" }
  let(:album) do
    OpenStruct.new(
      title: album_title,
      hit: song,
      songs: songs, # TODO: document this requirement,
      band: Struct.new(:name, :label).new("Epitaph", OpenStruct.new),
      producer: Struct.new(:name).new("Sun Records")
    )
  end
  let(:song)  { OpenStruct.new(title: "Downtown") }
  let(:songs) { [song = OpenStruct.new(title: "Calling"), song] }
  let(:form)  { AlbumForm.new(album) }

  describe "#validate with invalid array property" do
    it do
      refute form.validate(
        title: "Swimming Pool - EP",
        band: {
          name: "Marie Madeleine",
          label: {name: "Ekler'o'shocK"}
        },
        artists: [42, "Good Charlotte", 43]
      )
      assert_equal form.errors.messages, artists: {0 => ["must be a string"], 2 => ["must be a string"]}
      assert_equal form.errors.size, 1
    end
  end

  describe "#errors without #validate" do
    it do
      assert_equal form.errors.size, 0
    end
  end

  describe "blank everywhere" do
    before do
      form.validate(
        "hit" => {"title" => ""},
        "title" => "",
        "songs" => [{"title" => ""}, {"title" => ""}],
        "producer" => {"name" => ""}
      )
    end

    it do
      assert_equal form.errors.messages,{
        title: ["must be filled"],
        "hit.title": ["must be filled"],
        "songs.title": ["must be filled"],
        "band.label.name": ["must be filled"],
        "producer.name": ["must be filled"]
      }
    end

    # it do
    #   form.errors.must_equal({:title  => ["must be filled"]})
    #   TODO: this should only contain local errors?
    # end

    # nested forms keep their own Errors:
    it { assert_equal form.producer.errors.messages, name: ["must be filled"] }
    it { assert_equal form.hit.errors.messages, title: ["must be filled"] }
    it { assert_equal form.songs[0].errors.messages, title: ["must be filled"] }

    it do
      assert_equal form.errors.messages, {
        title: ["must be filled"],
        "hit.title": ["must be filled"],
        "songs.title": ["must be filled"],
        "band.label.name": ["must be filled"],
        "producer.name": ["must be filled"]
      }
      assert_equal form.errors.size, 5
    end
  end

  describe "#validate with main form invalid" do
    it do
      refute form.validate("title" => "", "band" => {"label" => {name: "Fat Wreck"}}, "producer" => nil)
      assert_equal form.errors.messages, title: ["must be filled"], producer: ["must be a hash"]
      assert_equal form.errors.size, 2
    end
  end

  describe "#validate with middle nested form invalid" do
    before { @result = form.validate("hit" => {"title" => ""}, "band" => {"label" => {name: "Fat Wreck"}}) }

    it { refute @result }
    it { assert_equal form.errors.messages, "hit.title": ["must be filled"] }
    it { assert_equal form.errors.size, 1 }
  end

  describe "#validate with collection form invalid" do
    before { @result = form.validate("songs" => [{"title" => ""}], "band" => {"label" => {name: "Fat Wreck"}}) }

    it { refute @result }
    it { assert_equal form.errors.messages, "songs.title": ["must be filled"] }
    it { assert_equal form.errors.size, 1 }
  end

  describe "#validate with collection and 2-level-nested invalid" do
    before { @result = form.validate("songs" => [{"title" => ""}], "band" => {"label" => {}}) }

    it { refute @result }
    it { assert_equal form.errors.messages, "songs.title": ["must be filled"], "band.label.name": ["must be filled"] }
    it { assert_equal form.errors.size, 2 }
  end

  describe "#validate with nested form using :base invalid" do
    it do
      result = form.validate("songs" => [{"title" => "Someday"}], "band" => {"name" => "Nickelback", "label" => {"name" => "Roadrunner Records"}})
      refute result
      assert_equal form.errors.messages, "band.name": ["you're a bad person"]
      assert_equal form.errors.size, 1
    end
  end

  describe "#add" do
    let(:album_title) { nil }
    it do
      result = form.validate("songs" => [{"title" => "Someday"}], "band" => {"name" => "Nickelback", "label" => {"name" => "Roadrunner Records"}})
      refute result
      assert_equal form.errors.messages, title: ["must be filled"], "band.name": ["you're a bad person"]
      # add a new custom error
      form.errors.add(:policy, "error_text")
      assert_equal form.errors.messages, title: ["must be filled"], "band.name": ["you're a bad person"], policy: ["error_text"]
      # does not duplicate errors
      form.errors.add(:title, "must be filled")
      assert_equal form.errors.messages, title: ["must be filled"], "band.name": ["you're a bad person"], policy: ["error_text"]
      # merge existing errors
      form.errors.add(:policy, "another error")
      assert_equal form.errors.messages, title: ["must be filled"], "band.name": ["you're a bad person"], policy: ["error_text", "another error"]
    end
  end

  describe "correct #validate" do
    before do
      @result = form.validate(
        "hit"   => {"title" => "Sacrifice"},
        "title" => "Second Heat",
        "songs" => [{"title" => "Heart Of A Lion"}],
        "band"  => {"label" => {name: "Fat Wreck"}}
      )
    end

    it { assert @result }
    it { assert_equal form.hit.title, "Sacrifice" }
    it { assert_equal form.title, "Second Heat" }
    it { assert_equal form.songs.first.title, "Heart Of A Lion" }
    it do
      skip "WE DON'T NEED COUNT AND EMPTY? ON THE CORE ERRORS OBJECT"
      assert_equal form.errors.size, 0
      assert form.errors.empty
    end
  end

  describe "Errors#to_s" do
    before { form.validate("songs" => [{"title" => ""}], "band" => {"label" => {}}) }

    # to_s is aliased to messages
    it {
      skip "why do we need Errors#to_s ?"
      assert_equal form.errors.to_s, "{:\"songs.title\"=>[\"must be filled\"], :\"band.label.name\"=>[\"must be filled\"]}"
    }
  end
end
