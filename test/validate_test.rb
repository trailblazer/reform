require 'test_helper'

class ValidateTest < BaseTest
  describe "populated" do
    let (:params) {
      {
        "title" => "Best Of",
        "hit"   => {"title" => "Roxanne"},
        "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
      }
    }

    subject { AlbumForm.new(Album.new(nil, Song.new, [Song.new, Song.new])) }

    before { subject.validate(params) }

    it { subject.title.must_equal "Best Of" }

    it { subject.hit.must_be_kind_of Reform::Form }
    it { subject.hit.title.must_equal "Roxanne" }

    it { subject.songs.must_be_kind_of Array }
    it { subject.songs.size.must_equal 2 }

    it { subject.songs[0].must_be_kind_of Reform::Form }
    it { subject.songs[0].title.must_equal "Fallout" }

    it { subject.songs[1].must_be_kind_of Reform::Form }
    it { subject.songs[1].title.must_equal "Roxanne" }
  end

  # TODO: the following tests go to populate_test.rb
  describe "manual setup with populator" do
    let (:form) {
      Class.new(Reform::Form) do
        property :hit, :populator => lambda { |fragment, args|
          puts "******************* #{fragment}"

          hit or self.hit = args.binding[:form].new(Song.new)
        } do
          property :title
        end
      end
     }

    let (:params) {
      {
        "hit"   => {"title" => "Roxanne"},
        # "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
      }
    }

    subject { form.new(Album.new) }

    before { subject.validate(params) }

    it { subject.hit.title.must_equal "Roxanne" }
  end


  describe ":populator, half-populated collection" do
    let (:form) {
      Class.new(Reform::Form) do
        collection :songs, :populator => lambda { |fragment, index, args|
          songs[index] or songs[index] = args.binding[:form].new(Song.new)
        } do
          property :title
        end
      end
     }

    let (:params) {
      {
        "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
      }
    }
    let (:song) { Song.new("Englishman") }

    subject { form.new(Album.new("Hits", nil, [song])) }

    before { subject.validate(params) }

    it { subject.songs[0].model.object_id.must_equal song.object_id } # this song was existing before.
    it { subject.songs[0].title.must_equal "Fallout" }
    it { subject.songs[1].title.must_equal "Roxanne" }
  end


  # not sure if we should catch that in Reform or rather do that in disposable. this is https://github.com/apotonick/reform/pull/104
  # describe ":populator with :empty" do
  #   let (:form) {
  #     Class.new(Reform::Form) do
  #       collection :songs, :empty => true, :populator => lambda { |fragment, index, args|
  #         songs[index] = args.binding[:form].new(Song.new)
  #       } do
  #         property :title
  #       end
  #     end
  #    }

  #   let (:params) {
  #     {
  #       "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
  #     }
  #   }

  #   subject { form.new(Album.new("Hits", [], [])) }

  #   before { subject.validate(params) }

  #   it { subject.songs[0].title.must_equal "Fallout" }
  #   it { subject.songs[1].title.must_equal "Roxanne" }
  # end


  describe ":populate_if_empty, half-populated collection" do
    let (:form) {
      Class.new(Reform::Form) do
        collection :songs, :populate_if_empty => Song do
          property :title
        end
      end
     }

    let (:params) {
      {
        "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}]
      }
    }
    let (:song) { Song.new("Englishman") }

    subject { form.new(Album.new("Hits", nil, [song])) }

    before { subject.validate(params) }

    it { subject.songs[0].model.object_id.must_equal song.object_id } # this song was existing before.
    it { subject.songs[0].title.must_equal "Fallout" }
    it { subject.songs[1].title.must_equal "Roxanne" }
  end


  describe ":populate_if_empty" do
    let (:form) {
      Class.new(Reform::Form) do
        property :hit, :populate_if_empty => lambda { |fragment, args| Song.new } do
          property :title
        end

        collection :songs, :populate_if_empty => lambda { |fragment, args| model.songs.build } do
          property :title
        end

        property :band, :populate_if_empty => lambda { |fragment, args| Band.new } do
          property :label, :populate_if_empty => lambda { |fragment, args| Label.new } do
            property :name
          end
        end
      end
     }

    let (:params) {
      {
        "hit"   => {"title" => "Roxanne"},
        "songs" => [{"title" => "Fallout"}, {"title" => "Roxanne"}],
        "band"  => {"label" => {"name" => "Epitaph"}}
      }
    }

    let (:song_collection_proxy) { Class.new(Array) { def build; Song.new; end } }
    let (:album) { Album.new(nil,nil, song_collection_proxy.new, nil) }
    subject { form.new(album) } # DISCUSS: require at least an array here? this is provided by all ORMs.

    before { subject.validate(params) }

    it { subject.hit.title.must_equal "Roxanne" }
    it { subject.songs[0].title.must_equal "Fallout" }
    it { subject.songs[1].title.must_equal "Roxanne" }

    # population doesn't write to the model.
    it { album.hit.must_equal nil }
    it { album.songs.size.must_equal 0 }

    it { subject.band.label.name.must_equal "Epitaph" }


    describe "missing parameters" do
      let (:params) {
        { }
      }

      before { subject.validate(params) }

      it { subject.hit.must_equal nil }
    end
  end


  describe "populate_if_empty: Class" do
    let (:form) {
      Class.new(Reform::Form) do
        property :hit, :populate_if_empty => Song do
          property :title
        end
      end
     }

    let (:params) {
      {
        "hit"   => {"title" => "Roxanne"},
      }
    }

    let (:album) { Album.new }
    subject { form.new(album) }

    before { subject.validate(params) }

    it { subject.hit.title.must_equal "Roxanne" }
  end



  # test cardinalities.
  describe "with empty collection and cardinality" do
    let (:album) { Album.new }

    subject { Class.new(Reform::Form) do
      include Reform::Form::ActiveModel
      model :album

      collection :songs do
        property :title
      end

      property :hit do
        property :title
      end

      validates :songs, :length => {:minimum => 1}
      validates :hit, :presence => true
    end.new(album) }


    describe "invalid" do
      before { subject.validate({}).must_equal false }

      it { subject.errors.messages.must_equal(
        :songs => ["is too short (minimum is 1 characters)"],
        :hit   => ["can't be blank"]) }
    end


    describe "valid" do
      let (:album) { Album.new(nil, Song.new, [Song.new("Urban Myth")]) }

      before {
        subject.validate({"songs" => [{"title"=>"Daddy, Brother, Lover, Little Boy"}], "hit" => {"title"=>"The Horse"}}).
          must_equal true
      }

      it { subject.errors.messages.must_equal({}) }
    end
  end


  describe "with symbols" do
    let (:album) { OpenStruct.new(:band => OpenStruct.new(:label => OpenStruct.new(:name => "Epitaph"))) }
    subject { ErrorsTest::AlbumForm.new(album) }
    let (:params) { {:band => {:label => {:name => "Stiff"}}, :title => "House Of Fun"} }

    before {
      subject.validate(params).must_equal true
    }

    it { subject.band.label.name.must_equal "Stiff" }
    it { subject.title.must_equal "House Of Fun" }
  end


  # providing manual validator method allows accessing form's API.
  describe "with ::validate" do
    let (:form) {
      Class.new(Reform::Form) do
        property :title

        validate :title?

        def title?
          errors.add :title, "not lowercase" if title == "Fallout"
        end
      end
     }

    let (:params) { {"title" => "Fallout"} }
    let (:song) { Song.new("Englishman") }

    subject { form.new(song) }

    before { @res = subject.validate(params) }

    it { @res.must_equal false }
    it { subject.errors.messages.must_equal({:title=>["not lowercase"]}) }
  end
end

# #validate(params)
#  title=(params[:title])
#  song.validate(params[:song], errors)

# #sync (assumes that forms already have updated fields)
#   model.title=
#   song.sync