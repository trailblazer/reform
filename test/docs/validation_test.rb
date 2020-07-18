require 'test_helper'
require 'reform/form/dry'

class DocsDryVTest < Minitest::Spec
  #:basic
  class AlbumForm < Reform::Form
    feature Reform::Form::Dry

    property :name

    validation do
      params do
        required(:name).filled
      end
    end
  end
  #:basic end

  it 'validates correctly' do
    form = DocsDryVTest::AlbumForm.new(Album.new(nil, nil, nil))
    result = form.call(name: nil)

    refute result.success?
    assert_equal({ name: ['must be filled'] }, form.errors.messages)
  end
end

class DocsDryVWithRulesTest < Minitest::Spec
  #:basic_with_rules
  class AlbumForm < Reform::Form
    feature Reform::Form::Dry

    property :name

    validation name: :default do
      option :form

      params do
        required(:name).filled
      end

      rule(:name) do
        key.failure('must be unique') if Album.where.not(id: form.model.id).where(name: value).exists?
      end
    end
  end
  #:basic_with_rules end

  it 'validates correctly' do
    Album = Struct.new(:name, :songs, :artist, :user)
    form = DocsDryVWithRulesTest::AlbumForm.new(Album.new(nil, nil, nil, nil))
    result = form.call(name: nil)

    refute result.success?
    assert_equal({ name: ['must be filled'] }, form.errors.messages)
  end
end

class DryVWithNestedTest < Minitest::Spec
  #:nested
  class AlbumForm < Reform::Form
    feature Reform::Form::Dry

    property :name

    validation do
      params { required(:name).filled }
    end

    property :artist do
      property :name

      validation do
        params { required(:name).filled }
      end
    end
  end
  #:nested end

  it 'validates correctly' do
    form = DryVWithNestedTest::AlbumForm.new(Album.new(nil, nil, Artist.new(nil)))
    result = form.call(name: nil, artist: { name: '' })

    refute result.success?
    assert_equal({ name: ['must be filled'], 'artist.name': ['must be filled'] }, form.errors.messages)
  end
end

class DryVValGroupTest < Minitest::Spec
  class AlbumForm < Reform::Form
    feature Reform::Form::Dry

    property :name
    property :artist
    #:validation_groups
    validation name: :default do
      params { required(:name).filled }
    end

    validation name: :artist, if: :default do
      params { required(:artist).filled }
    end

    validation name: :famous, after: :default do
      params { optional(:artist) }

      rule(:artist) do
        if value
          key.failure('only famous artist') unless value =~ /famous/
        end
      end
    end
    #:validation_groups end
  end

  it 'validates correctly' do
    form = DryVValGroupTest::AlbumForm.new(Album.new(nil, nil, nil))
    result = form.call(name: nil)

    refute result.success?
    assert_equal({ name: ['must be filled'] }, result.errors.messages)

    result = form.call(name: 'Title')
    refute result.success?
    assert_equal({ artist: ['must be filled'] }, result.errors.messages)

    result = form.call(name: 'Title', artist: 'Artist')
    refute result.success?
    assert_equal({ artist: ['only famous artist'] }, result.errors.messages)

    result = form.call(name: 'Title', artist: 'Artist famous')
    assert result.success?
  end
end
