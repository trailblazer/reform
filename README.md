# Reform

[![Gitter Chat](https://badges.gitter.im/trailblazer/chat.svg)](https://gitter.im/trailblazer/chat)
[![TRB Newsletter](https://img.shields.io/badge/TRB-newsletter-lightgrey.svg)](http://trailblazer.to/newsletter/)
[![Build
Status](https://travis-ci.org/trailblazer/reform.svg)](https://travis-ci.org/trailblazer/reform)
[![Gem Version](https://badge.fury.io/rb/reform.svg)](http://badge.fury.io/rb/reform)

_Form objects decoupled from your models._

Reform gives you a form object with validations and nested setup of models. It is completely framework-agnostic and doesn't care about your database.

Although reform can be used in any Ruby framework, it comes with [Rails support](#rails-integration), works with [simple_form and other form gems](#formbuilder-support), allows nesting forms to implement [has_one](#nesting-forms-1-1-relations) and [has_many](#nesting-forms-1-n-relations) relationships, can [compose a form](#compositions) from multiple objects and gives you [coercion](#coercion).

## Full Documentation

Reform is part of the [Trailblazer](http://trailblazer.to) framework. [Full documentation](http://trailblazer.to/gems/reform) is available on the project site.

## Reform 2.2

Temporary note: Reform 2.2 does **not automatically load Rails files** anymore (e.g. `ActiveModel::Validations`). You need the `reform-rails` gem, see [Installation](#installation).

## Defining Forms

Forms are defined in separate classes. Often, these classes partially map to a model.

```ruby
class AlbumForm < Reform::Form
  property :title
  validates :title, presence: true
end
```

Fields are declared using `::property`. Validations work exactly as you know it from Rails or other frameworks. Note that validations no longer go into the model.


## The API

Forms have a ridiculously simple API with only a handful of public methods.

1. `#initialize` always requires a model that the form represents.
2. `#validate(params)` updates the form's fields with the input data (only the form, _not_ the model) and then runs all validations. The return value is the boolean result of the validations.
3. `#errors` returns validation messages in a classic ActiveModel style.
4. `#sync` writes form data back to the model. This will only use setter methods on the model(s).
5. `#save` (optional) will call `#save` on the model and nested models. Note that this implies a `#sync` call.
6. `#prepopulate!` (optional) will run pre-population hooks to "fill out" your form before rendering.

In addition to the main API, forms expose accessors to the defined properties. This is used for rendering or manual operations.


## Setup

In your controller or operation you create a form instance and pass in the models you want to work on.

```ruby
class AlbumsController
  def new
    @form = AlbumForm.new(Album.new)
  end
```

This will also work as an editing form with an existing album.

```ruby
def edit
  @form = AlbumForm.new(Album.find(1))
end
```

Reform will read property values from the model in setup. In our example, the `AlbumForm` will call `album.title` to populate the `title` field.

## Rendering Forms

Your `@form` is now ready to be rendered, either do it yourself or use something like Rails' `#form_for`, `simple_form` or `formtastic`.

```haml
= form_for @form do |f|
  = f.input :title
```

Nested forms and collections can be easily rendered with `fields_for`, etc. Note that you no longer pass the model to the form builder, but the Reform instance.

Optionally, you might want to use the `#prepopulate!` method to pre-populate fields and prepare the form for rendering.


## Validation

After form submission, you need to validate the input.

```ruby
class SongsController
  def create
    @form = SongForm.new(Song.new)

    #=> params: {song: {title: "Rio", length: "366"}}

    if @form.validate(params[:song])
```

The `#validate` method first updates the values of the form - the underlying model is still treated as immutuable and *remains unchanged*. It then runs all validations you provided in the form.

It's the only entry point for updating the form. This is per design, as separating writing and validation doesn't make sense for a form.

This allows rendering the form after `validate` with the data that has been submitted. However, don't get confused, the model's values are still the old, original values and are only changed after a `#save` or `#sync` operation.


## Syncing Back

After validation, you have two choices: either call `#save` and let Reform sort out the rest. Or call `#sync`, which will write all the properties back to the model. In a nested form, this works recursively, of course.

It's then up to you what to do with the updated models - they're still unsaved.


## Saving Forms

The easiest way to save the data is to call `#save` on the form.

```ruby
if @form.validate(params[:song])
  @form.save  #=> populates album with incoming data
              #   by calling @form.album.title=.
else
  # handle validation errors.
end
```

This will sync the data to the model and then call `album.save`.

Sometimes, you need to do saving manually.

## Default values

Reform allows default values to be provided for properties.

```ruby
class AlbumForm < Reform::Form
  property :price_in_cents, default: 9_95
end
```

## Saving Forms Manually

Calling `#save` with a block will provide a nested hash of the form's properties and values. This does **not call `#save` on the models** and allows you to implement the saving yourself.

The block parameter is a nested hash of the form input.

```ruby
  @form.save do |hash|
    hash      #=> {title: "Greatest Hits"}
    Album.create(hash)
  end
```

You can always access the form's model. This is helpful when you were using populators to set up objects when validating.

```ruby
  @form.save do |hash|
    album = @form.model

    album.update_attributes(hash[:album])
  end
```


## Nesting

Reform provides support for nested objects. Let's say the `Album` model keeps some associations.

```ruby
class Album < ActiveRecord::Base
  has_one  :artist
  has_many :songs
end
```

The implementation details do not really matter here, as long as your album exposes readers and writes like `Album#artist` and `Album#songs`, this allows you to define nested forms.


```ruby
class AlbumForm < Reform::Form
  property :title
  validates :title, presence: true

  property :artist do
    property :full_name
    validates :full_name, presence: true
  end

  collection :songs do
    property :name
  end
end
```

You can also reuse an existing form from elsewhere using `:form`.

```ruby
property :artist, form: ArtistForm
```

## Nested Setup

Reform will wrap defined nested objects in their own forms. This happens automatically when instantiating the form.

```ruby
album.songs #=> [<Song name:"Run To The Hills">]

form = AlbumForm.new(album)
form.songs[0] #=> <SongForm model: <Song name:"Run To The Hills">>
form.songs[0].name #=> "Run To The Hills"
```

### Nested Rendering

When rendering a nested form you can use the form's readers to access the nested forms.

```haml
= text_field :title,         @form.title
= text_field "artist[name]", @form.artist.name
```

Or use something like `#fields_for` in a Rails environment.

```haml
= form_for @form do |f|
  = f.text_field :title

  = f.fields_for :artist do |a|
    = a.text_field :name
```

## Nested Processing

`validate` will assign values to the nested forms. `sync` and `save` work analogue to the non-nested form, just in a recursive way.

The block form of `#save` would give you the following data.

```ruby
@form.save do |nested|
  nested #=> {title:  "Greatest Hits",
         #    artist: {name: "Duran Duran"},
         #    songs: [{title: "Hungry Like The Wolf"},
         #            {title: "Last Chance On The Stairways"}]
         #   }
  end
```

The manual saving with block is not encouraged. You should rather check the Disposable docs to find out how to implement your manual tweak with the official API.


## Populating Forms

Very often, you need to give Reform some information how to create or find nested objects when `validate`ing. This directive is called _populator_ and [documented here](http://trailblazer.to/gems/reform/populator.html).

## Installation

Add this line to your Gemfile:

```ruby
gem "reform"
```

Reform works fine with Rails 3.1-5.0. However, inheritance of validations with `ActiveModel::Validations` is broken in Rails 3.2 and 4.0.

Since Reform 2.2, you have to add the `reform-rails` gem to your `Gemfile` to automatically load ActiveModel/Rails files.

```ruby
gem "reform-rails"
```

Since Reform 2.0 you need to specify which **validation backend** you want to use (unless you're in a Rails environment where ActiveModel will be used).

To use ActiveModel (not recommended because very out-dated).

```ruby
require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end
```

To use dry-validation (recommended).

```ruby
require "reform/form/dry"
Reform::Form.class_eval do
  feature Reform::Form::Dry
end
```

Put this in an initializer or on top of your script.


## Compositions

Reform allows to map multiple models to one form. The [complete documentation](https://github.com/apotonick/disposable#composition) is here, however, this is how it works.

```ruby
class AlbumForm < Reform::Form
  include Composition

  property :id,    on: :album
  property :title, on: :album
  property :songs, on: :cd
  property :cd_id, on: :cd, from: :id
end
```
When initializing a composition, you have to pass a hash that contains the composees.

```ruby
AlbumForm.new(album: album, cd: CD.find(1))
```

## More

Reform comes many more optional features, like hash fields, coercion, virtual fields, and so on. Check the [full documentation here](http://trailblazer.to/gems/reform).

[![](http://trailblazer.to/images/3dbuch-freigestellt.png)](https://leanpub.com/trailblazer)

Reform is part of the [Trailblazer project](http://trailblazer.to). Please [buy my book](https://leanpub.com/trailblazer) to support the development and learn everything about Reform - there's two chapters dedicated to Reform!


## Security And Strong_parameters

By explicitly defining the form layout using `::property` there is no more need for protecting from unwanted input. `strong_parameter` or `attr_accessible` become obsolete. Reform will simply ignore undefined incoming parameters.

## This is not Reform 1.x!

Temporary note: This is the README and API for Reform 2. On the public API, only a few tiny things have changed. Here are the [Reform 1.2 docs](https://github.com/trailblazer/reform/blob/v1.2.6/README.md).

Anyway, please upgrade and _report problems_ and do not simply assume that we will magically find out what needs to get fixed. When in trouble, join us on [Gitter](https://gitter.im/trailblazer/chat).

[Full documentation for Reform](http://trailblazer.to/gems/reform) is available online, or support us and grab the [Trailblazer book](https://leanpub.com/trailblazer). There is an [Upgrading Guide](http://trailblazer.to/gems/reform/upgrading-guide.html) to help you migrate from Reform 1.x.

### Attributions!!!

Great thanks to [Blake Education](https://github.com/blake-education) for giving us the freedom and time to develop this project in 2013 while working on their project.
