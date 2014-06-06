class CompositionTest < ReformSpec
  class SongAndArtist < Reform::Composition
    map({:artist => [[:name]], :song => [[:title]]}) #SongAndArtistMap.representable_attrs
  end

  let (:comp) { SongAndArtist.new(:artist => @artist=OpenStruct.new, :song => rio) }

  it "delegates to models as defined" do
    comp.name.must_equal nil
    comp.title.must_equal "Rio"
  end

  it "raises when non-mapped property" do
    assert_raises NoMethodError do
      comp.raise_an_exception
    end
  end

  describe "::from" do
    it "creates the same mapping" do
      comp =
      Reform::Composition.from(
          Class.new(Reform::Representer) do
            property :name,  :on => :artist
            property :title, :on => :song
          end
        ).
      new(:artist => duran, :song => rio)

      comp.name.must_equal "Duran Duran"
      comp.title.must_equal "Rio"
    end
  end


  describe "#nested_hash_for" do
    it "returns nested hash" do
      comp.nested_hash_for(:name => "Jimi Hendrix", :title => "Fire").must_equal({:artist=>{:name=>"Jimi Hendrix"}, :song=>{:title=>"Fire"}})
    end

    it "works with strings" do
      comp.nested_hash_for("name" => "Jimi Hendrix", "title" => "Fire").must_equal({:artist=>{:name=>"Jimi Hendrix"}, :song=>{:title=>"Fire"}})
    end

    it "works with strings in map" do
      Class.new(Reform::Composition) do
        map(:artist => [["name"]])
      end.new({}).nested_hash_for(:name => "Jimi Hendrix").must_equal({:artist=>{:name=>"Jimi Hendrix"}})
    end
  end
end