require "test_helper"

class DesignTest < Minitest::Spec
  # 1. Decorate
  # 2. Deserialize
  # 3. Validate
  # 4. Persist/sync
  # 5. Present

  # ROM Changeset
  # task = tasks.transaction do
  #   user = users.changeset(:create, name: 'Jane').commit

  #   new_task = tasks.changeset(:create, title: 'Task One').associate(user)

  #   new_task.commit
  # end

  it "hydrate: creates object graph" do
    song_form = Class.new(Reform::Form) do
      property :title
      property :singer, virtual: true
      property :band do
        property :name
      end

      def header; "<h1>Create</h2>"; end
    end


  ## empty object has {nil} scalars
  ## virtual {singer} is not read
    empty_song = Song.new()
    hydrated = Reform::Hydrate.hydrate(song_form, empty_song, {})

    assert_equal hydrated.class, Reform::Form::Deserialized
    assert_equal hydrated[:model_from_populator].inspect, %{#<struct DesignTest::Song title=nil, band=nil, album_id=nil>}
    assert_nil   hydrated.title
    assert_nil hydrated.band

  ## we can access helpers from the form
    assert_equal hydrated.header, %{<h1>Create</h2>}
  end


  # 3. Validate
  Album = Struct.new(:title, :songs)
  Song = Struct.new(:title, :band, :album_id) do
    def save
      @persisted = true
    end
  end
  Band = Struct.new(:name, :label) do
    def save
      @persisted = true
    end
  end
  Label = Struct.new(:name, :url)

  it "what" do

    song = Song.new("Apocalypse soon", band = Band.new("")) # Could be done by Decorate()
    # assuming Validate() already happened

    song_form = Class.new(Reform::Form) do
      feature Reform::Form::Dry

      property :title
      property :band, populate_if_empty: Band do # DISCUSS: polymorphic
        property :name

        validation group_class: Reform::Form::Dry::Validations::Group do
          params do
            required(:name).filled
          end
        end
      end

      validation group_class: Reform::Form::Dry::Validations::Group do
        params do
          required(:title).filled
          required(:album_id).filled

          # required(:band).schema do
          #   required(:name).filled
          # end
        end
      end
    end


## empty object has {nil} scalars
  empty_song = OpenStruct.new(title: nil, band: OpenStruct.new(name: ""))
  hydrated = Reform::Hydrate.hydrate(song_form, empty_song, {})
  assert_equal hydrated.class, Reform::Form::Deserialized
  assert_equal hydrated[:model_from_populator].inspect, %{#<OpenStruct title=nil, band=#<OpenStruct name="">>}
  assert_nil   hydrated.title
  assert_equal hydrated.band[:model_from_populator].inspect, %{#<OpenStruct name="">}
  assert_equal "", hydrated.band.name

  existing_song = OpenStruct.new(title: "Apocalypse soon", band: OpenStruct.new(name: "Mute"))
  hydrated = Reform::Hydrate.hydrate(song_form, existing_song, {})
  assert_equal "Apocalypse soon", hydrated.title
  assert_equal "Mute", hydrated.band.name

  # at this point, the form is fully populated from Decorate and from Deserialize
  # title: "Apocalypse soon"
  # bands:
  #   type:rock-band
  #     name: "..."
  #   type:punk-band

  # song_form_instance = song_form.new#(song)

  params = {title: "The Brews", band: {name: "NOFX"}}

## deserialize/populate without paired model
  # deserialized_form = Reform::Deserialize.deserialize(song_form, params, nil, {}) # TODO: implement the {nil} model

## paired populate
##   there's a matching paired model for each form
  # Deserialize/Hydrate an empty form just by iterating the schema, and for each nested form node, instantiate a form.
  deserialized_form = Reform::Deserialize.deserialize(song_form, params, empty_song, {})

  assert_equal deserialized_form[:model_from_populator].inspect, %{#<OpenStruct title=nil, band=#<OpenStruct name=\"\">>}
  assert_equal "The Brews", deserialized_form.title
  assert_equal "The Brews", deserialized_form[:"title.value.read"]
  assert_equal({:name=>"NOFX"}, deserialized_form[:"band.value.read"])
  # assert_equal %{[:input, :populated_instance, :twin, :\"title.value.read\", :title, :\"band.value.read\", :band]}, ctx.keys.inspect
  # assert_equal %{Apocalypse soon}, twin.title
  assert_equal deserialized_form.band[:model_from_populator].inspect, %{#<OpenStruct name=\"\">}
  assert_equal "NOFX", deserialized_form.band.name
  assert_equal "NOFX", deserialized_form.band[:"name.value.read"]

## paired populate
##   there's no {band}, so we invoke {IfEmpty}

  deserialized_form = Reform::Deserialize.deserialize(song_form, params, Song.new(), {})

  assert_equal deserialized_form[:model_from_populator].inspect, %{#<struct DesignTest::Song title=nil, band=nil, album_id=nil>}
  assert_equal "The Brews", deserialized_form.title
  assert_equal "The Brews", deserialized_form[:"title.value.read"]
  assert_equal({:name=>"NOFX"}, deserialized_form[:"band.value.read"])
  # assert_equal %{[:input, :populated_instance, :twin, :\"title.value.read\", :title, :\"band.value.read\", :band]}, ctx.keys.inspect
  # assert_equal %{Apocalypse soon}, twin.title
  # {Band} instance created by {IfEmpty}.
  assert_equal deserialized_form.band[:model_from_populator].inspect, %{#<struct DesignTest::Band name=nil, label=nil>}
  assert_equal "NOFX", deserialized_form.band.name
  assert_equal "NOFX", deserialized_form.band[:"name.value.read"]


# # FIXME
# assert_raises do
#   assert_equal %{Apocalypse soon}, song_form_instance.title

# end

# d,c,t = deserialized_values[:band]
# assert_equal %{[:populated_instance, :twin, :input, :\"name.value.read\", :name]}, c.keys.inspect
# assert_raises do
#   assert_equal "", song_form_instance.band.name
# end

# assert_equal %{{:title=>"The Brews", :band=>{:name=>"NOFX"}}}, deserialized_values.inspect


validated_form = Reform::Validate.run_validations(nil, form_class: song_form, deserialized_form: deserialized_form)

# errors works
_(validated_form.success?).must_equal false
_(validated_form.errors[:title].inspect).must_equal %{[]}
_(validated_form.errors[:album_id].inspect).must_equal %{["is missing"]}

# accessors work
_(validated_form.title).must_equal "The Brews"
_(validated_form[:"title.value.read"]).must_equal "The Brews"

# nested errors work
_(validated_form.band.success?).must_equal true
_(validated_form.band.errors[:name].inspect).must_equal %{[]}
# nested accessors work
_(validated_form.band[:"name.value.read"].inspect).must_equal %{"NOFX"}



#pp deserialized_form.instance_variable_get(:@form)
raise deserialized_form.to_input_hash.inspect



Reform::Form::Save(deserialized_form)



# fuck mutable state
_(song.inspect).must_equal %{#<struct DesignTest::Song title=\"The Brews\", band=#<struct DesignTest::Band name=\"NOFX\">, album_id=nil>}

# pp validated_form
raise


# errors
song_form_instance = song_form.new(song)



# this happens during Deserialize()
song_form_instance.instance_variable_set(:@deserialized_values, {title: song_form_instance.title} )# FIXME: no nesting here, yet.
song_form_instance.band.instance_variable_set(:@deserialized_values, {name: song_form_instance.band.name})

# strong interfaces between deserialization and validation, encapsulating the parsing process
# Goal is to decouple the actual validation process from a) the to-be-validated-data source and b) ?
  # {form} is the value container. {form} is schema provider, {form} is also needed as an exec_context for validations

  # {#validate!} grabs {deserialized_values} from {values_object}
    result = Reform::Contract::Validate.validate!("nil", form: song_form_instance, validation_groups: song_form.validation_groups,

      values_object: song_form_instance,
      )

    pp result

    result.errors[:title].inspect.must_equal %{[]}
    result.errors[:album_id].inspect.must_equal %{["is missing"]}


    # test blank "" validation
  song_form_instance = song_form.new(song)
  song_form_instance.instance_variable_set(:@deserialized_values, {title: ""} )
  result = Reform::Contract::Validate.validate!("nil", form: song_form_instance, validation_groups: song_form.validation_groups,

      values_object: song_form_instance,
      )

    # pp result

    result.errors[:title].inspect.must_equal %{["must be filled"]} # correct message for blank string.
    result.errors[:album_id].inspect.must_equal %{["is missing"]}

  end

  # TODO: make {populate: false} default.
  it "{populate: false}" do
    song_form = Class.new(Reform::Form) do
      property :title
      property :band, populate: false do
        property :name
        property :label, populate: false do
          property :name
          property :url
        end
      end
    end

  ## model is {nil}
  ## We don't want any label, it's missing in {params}!
   # No paired models are created.
    params            = {title: "The Brews", band: {name: "NOFX"}}
    deserialized_form = Reform::Deserialize.deserialize(song_form, params, nil, {})

    song_and_band_assertions = test do |top_form_model: %{nil}, paired_band: %{nil}, **|
      assert_equal deserialized_form[:model_from_populator].inspect, top_form_model
      assert_equal "The Brews", deserialized_form.title
      assert_equal "The Brews", deserialized_form[:"title.value.read"]
      assert_equal deserialized_form.band[:model_from_populator].inspect, paired_band
      assert_equal "NOFX", deserialized_form.band.name
      assert_equal "NOFX", deserialized_form.band[:"name.value.read"]
    end
    assert_equal({:name=>"NOFX"}, deserialized_form[:"band.value.read"])
    assert_nil deserialized_form.band.label

  ## pass a model that is being ignored,
  ## it's still being set as the paired model on the top-form, though
    params            = {title: "The Brews", band: {name: "NOFX"}}
    deserialized_form = Reform::Deserialize.deserialize(song_form, params, "i am ignored", {})
    # top model is set, all other models are nil
    test song_and_band_assertions, top_form_model: %{"i am ignored"}
    assert_equal({:name=>"NOFX"}, deserialized_form[:"band.value.read"])
    assert_nil deserialized_form.band.label


  ## model is {nil}
  ## label included - we test 3rd-level NESTING
   # No paired models are created.
    params            = {title: "The Brews", band: {name: "NOFX", label: {name: "Fat Wreck"}}}
    deserialized_form = Reform::Deserialize.deserialize(song_form, params, nil, {})

    test song_and_band_assertions
    assert_equal deserialized_form[:"band.value.read"], {:name=>"NOFX", :label=>{:name=>"Fat Wreck"}}

    label_assertions = test do |paired_label: %{nil}|
      assert_equal deserialized_form.band[:"label.value.read"], {:name=>"Fat Wreck"}
      assert_equal deserialized_form.band.label[:"name.value.read"], "Fat Wreck"
      assert_equal deserialized_form.band.label[:model_from_populator].inspect, paired_label
    end

  ## model is 3-level containing all required readable models
   # No paired models are created via populator (we can read or "sync" them)!

    song_form = Class.new(Reform::Form) do
      property :title
      property :band, populate_if_empty: Class do
        property :name
        property :label, populate_if_empty: Class do
          property :name
          property :url
        end
      end
    end

    song              = Song.new("XXX", Band.new("YYY", Label.new("ZZZ")))
    params            = {title: "The Brews", band: {name: "NOFX", label: {name: "Fat Wreck"}}}
    deserialized_form = Reform::Deserialize.deserialize(song_form, params, song, {})

    test song_and_band_assertions,
      top_form_model: %{#<struct DesignTest::Song title="XXX", band=#<struct DesignTest::Band name="YYY", label=#<struct DesignTest::Label name="ZZZ", url=nil>>, album_id=nil>},
      paired_band:    %{#<struct DesignTest::Band name="YYY", label=#<struct DesignTest::Label name="ZZZ", url=nil>>}
    test label_assertions,
      paired_label: %{#<struct DesignTest::Label name="ZZZ", url=nil>}
  end
end
