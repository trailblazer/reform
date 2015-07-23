# Reform

[![Build
Status](https://travis-ci.org/apotonick/reform.svg)](https://travis-ci.org/apotonick/reform)
[![Gem Version](https://badge.fury.io/rb/reform.svg)](http://badge.fury.io/rb/reform)

_Form objects decoupled from your models._

Reform gives you a form object with validations and nested setup of models. It is completely framework-agnostic and doesn't care about your database.

Although reform can be used in any Ruby framework, it comes with [Rails support](#rails-integration), works with [simple_form and other form gems](#formbuilder-support), allows nesting forms to implement [has_one](#nesting-forms-1-1-relations) and [has_many](#nesting-forms-1-n-relations) relationships, can [compose a form](#compositions) from multiple objects and gives you [coercion](#coercion).

## This is not Reform 1.x!

Temporary note: This is the README and API for Reform 2. On the public API, only a few tiny things have changed. When in trouble, join us on the IRC (Freenode) #trailblazer channel.

[Full documentation for Reform](http://trailblazerb.org/gems/reform) is available online, or support us and grab the [Trailblazer book](https://leanpub.com/trailblazer).

## Disposable

Every form in Reform is a _twin_. Twins are non-persistent domain objects from the [Disposable gem](https://github.com/apotonick/disposable). All features of Disposable, like renaming fields, change tracking, etc. are available in Reform, too.

<!--
## ActiveModel

**WARNING: Reform will soon drop support for ActiveModel validations.**

This is mostly to save my mental integrity. The amount of problems we have in Reform with ActiveModel's poor object design, its lack of interfaces and encapsulation do outweigh the benefits. Please consider using Lotus::Validations instead, which will soon be mature enough to replace this dinosaur.
-->

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


## Populating Forms for Validation

This topic is thorougly covered in the [Trailblazer book](https://leanpub.com/trailblazer) in chapters _Nested Forms_ and _Mastering Forms_.

With a complex nested setup it can sometimes be painful to setup the model object graph.

Let's assume you rendered the following form.

```ruby
@form = AlbumForm.new(Album.new(songs: [Song.new, Song.new]))
```

This will render two nested forms to create new songs.

In `validate`, you're supposed to setup the very same object graph, again. Reform has no way of remembering what the object setup was like a request ago.

So, the following code will fail.

```ruby
@form = AlbumForm.new(Album.new).validate(params[:album])
```

However, you can advise Reform to setup the correct objects for you.

```ruby
class AlbumForm < Reform::Form
  collection :songs, populate_if_empty: Song do
    # ..
  end
```

This works for both `property` and `collection` and instantiates `Song` objects where they're missing when calling `#validate`.

If you want to create the objects yourself, because you're smarter than Reform, do it with a lambda.

```ruby
class AlbumForm < Reform::Form
  collection :songs, populate_if_empty: lambda { |fragment, args| Song.new } do
    # ..
  end
```

Reform also allows to completely override population using the `:populator` options. This is [documented here](http://trailblazerb.org/gems/reform/populators.html), and also in the Trailblazer book.

## Installation

Add this line to your Gemfile:

```ruby
gem 'reform'
```

Reform works fine with Rails 3.1-4.2. However, inheritance of validations with `ActiveModel::Validations` is broken in Rails 3.2 and 4.0.

Since Reform 2.0 you need to specify which **validation backend** you want to use (unless you're in a Rails environment where ActiveModel will be used).

To use ActiveModel (not recommended as it doesn't support removing validations).

```ruby
require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end
```

To use Lotus validations (recommended).

```ruby
require "reform/form/lotus"
Reform::Form.class_eval do
  include Reform::Form::Lotus
end
```

Put this in an initializer or on top of your script.


## Compositions

Reform allows to map multiple models to one form. The [complete documentation](https://github.com/apotonick/disposable#composition) is here, however, this is how it works.

```ruby
class AlbumTwin < Reform::Form
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

=> rendering
=> sync with block

## Hash Fields

Reform can also handle deeply nested hash fields from serialized hash columns. This is [documented here](https://github.com/apotonick/disposable#struct).

=> Example

<a href="https://leanpub.com/trailblazer">
![](https://raw.githubusercontent.com/apotonick/trailblazer/master/doc/trb.jpg)
</a>

Reform is part of the [Trailblazer project](https://github.com/apotonick/trailblazer). Please [buy my book](https://leanpub.com/trailblazer) to support the development and learn everything about Reform. Currently the book discusses:

* Form objects, the DSL and basic API (chapter 2 and 3)
* Basic validations and rendering forms (chapter 3)
* Nested forms, prepopulating and validation populating and pre-selecting values (chapter 5)

More chapters are coming!




## Nomenclature

Reform comes with two base classes.

* `Form` is what made you come here - it gives you a form class to handle all validations, wrap models, allow rendering with Rails form helpers, simplifies saving of models, and more.
* `Contract` gives you a sub-set of `Form`: [this class](#contracts) is meant for API validation where already populated models get validated without having to maintain validations in the model classes.



Luckily, this can be shortened as follows.

```ruby
class SongForm < Reform::Form
  property :title, validates: {presence: true}
  property :length, validates: {numericality: true}
end
```

Use `properties` to bulk-specify fields.

```ruby
class SongForm < Reform::Form
  properties :title, :length, validates: {presence: true} # both required!
  validates :length, numericality: true
end
```



If the form wraps multiple models, via [composition](#compositions), you can access them like this:

```ruby
  @form.save do |nested|
    song = @form.model[:song]
    label = @form.model[:label]
  end
```

Note that you can call `#sync` and _then_ call `#save { |hsh| }` to save models yourself.


## Contracts

Contracts give you a sub-set of the `Form` API.

1. `#initialize` accepts an already populated model.
2. `#validate` will run defined validations (without accepting a params hash as in `Form`).

Contracts can be used to completely remove validation logic from your model classes. Validation should happen in a separate layer - a `Contract`.

### Defining Contracts

A contract looks like a form.

```ruby
class AlbumContract < Reform::Contract
  property :title
  validates :title, length: {minimum: 9}

  collection :songs do
    property :title
    validates :title, presence: true
  end
```

It defines the validations and the object graph to be inspected.

In future versions and with the upcoming [Trailblazer framework](https://github.com/apotonick/trailblazer), contracts can be inherited from forms, representers, and cells, and vice-versa. Actually this already works with representer inheritance - let me know if you need help.

### Using Contracts

Applying a contract is simple, all you need is a populated object (e.g. an album after `#assign_attributes`).

```ruby
album.assign_attributes(..)

contract = AlbumContract.new(album)

if contract.validate
  album.save
else
  raise contract.errors.messages.inspect
end
```

Contracts help you to make your data layer a dumb persistance tier. My [upcoming book discusses that in detail](http://nicksda.apotomo.de).

```

This basically works like a nested `property` that iterates over a collection of songs.



### Turning Off Autosave

You can assign Reform to _not_ call `save` on a particular nested model (per default, it is called automatically on all nested models).

```ruby
class AlbumForm < Reform::Form
  # ...

  collection :songs, save: false do
    # ..
  end
```

The `:save` options set to false won't save models.





## Compositions

Sometimes you might want to embrace two (or more) unrelated objects with a single form. While you could write a simple delegating composition yourself, reform comes with it built-in.

Say we were to edit a song and the label data the record was released from. Internally, this would imply working on the `songs` table and the `labels` table.

```ruby
class SongWithLabelForm < Reform::Form
  include Composition

  property :title, on: :song
  property :city,  on: :label

  model :song # only needed in ActiveModel context.

  validates :title, :city, presence: true
end
```

Note that reform needs to know about the owner objects of properties. You can do so by using the `on:` option.

Also, the form needs to have a main object configured. This is where ActiveModel-methods like `#persisted?` or '#id' are delegated to. Use `::model` to define the main object.


### Composition: Setup

The constructor slightly differs.

```ruby
@form = SongWithLabelForm.new(song: Song.new, label: Label.new)
```

### Composition: Rendering

After you configured your composition in the form, reform hides the fact that you're actually showing two different objects.

```haml
= form_for @form do |f|

  Song:     = f.input :title

  Label in: = f.input :city
```

### Composition: Processing

When using `#save' without a block reform will use writer methods on the different objects to push validated data to the properties.

Here's what the block parameters look like.

```ruby
@form.save do |nested|

  nested #=> {
         #   song:  {title: "Rio"}
         #   label: {city: "London"}
         #   }
end
```


## Forms In Modules

To maximize reusability, you can also define forms in modules and include them in other modules or classes.

```ruby
module SongsForm
  include Reform::Form::Module

  collection :songs do
    property :title
    validates :title, presence: true
  end
end
```

This can now be included into a real form.

```ruby
class AlbumForm < Reform::Form
  property :title

  include SongsForm
end
```

Note that you can also override properties [using inheritance](#inheritance) in Reform.

When using coercion, make sure the including form already contains the `Coercion` module.


## Inheritance

Forms can be derived from other forms and will inherit all properties and validations.

```ruby
class AlbumForm < Reform::Form
  property :title

  collection :songs do
    property :title

    validates :title, presence: true
  end
end
```

Now, a simple inheritance can add fields.

```ruby
class CompilationForm < AlbumForm
  property :composers do
    property :name
  end
end
```

This will _add_ `composers` to the existing fields.

You can also partially override fields using `:inherit`.

```ruby
class CompilationForm < AlbumForm
  property :songs, inherit: true do
    property :band_id
    validates :band_id, presence: true
  end
end
```

Using `inherit:` here will extend the existing `songs` form with the `band_id` field. Note that this simply uses [representable's inheritance mechanism](https://github.com/apotonick/representable/#partly-overriding-properties).

## Coercion

Often you want incoming form data to be converted to a type, like timestamps. Reform uses [virtus](https://github.com/solnic/virtus) for coercion, the DSL is seamlessly integrated into Reform with the `:type` option.

### Virtus Coercion

Be sure to add `virtus` to your Gemfile.

```ruby
require 'reform/form/coercion'

class SongForm < Reform::Form
  include Coercion

  property :written_at, type: DateTime
end

form.validate("written_at" => "26 September")
```

Coercion only happens in `#validate`.

```
form.written_at #=> <DateTime "2014 September 26 00:00">
```

### Manual Coercing Values

If you need to filter values manually, you can override the setter in the form.

```ruby
class SongForm < Reform::Form
  property :title

  def title=(value)
    super sanitize(value) # value is raw form input.
  end
end
```

As with the built-in coercion, this setter is only called in `#validate`.


## Virtual Attributes

Virtual fields come in handy when there's no direct mapping to a model attribute or when you plan on displaying but not processing a value.


### Virtual Fields

Often, fields like `password_confirmation` should neither be read from nor written back to the model. Reform comes with the `:virtual` option to handle that case.

```ruby
class PasswordForm < Reform::Form
  property :password
  property :password_confirmation, virtual: true
```

Here, the model won't be queried for a `password_confirmation` field when creating and rendering the form. When saving the form, the input value is not written to the decorated model. It is only readable in validations and when saving the form manually.

```ruby
form.validate("password" => "123", "password_confirmation" => "321")

form.password_confirmation #=> "321"
```

The nested hash in the block-`#save` provides the same value.

```ruby
form.save do |nested|
  nested[:password_confirmation] #=> "321"
```

### Read-Only Fields

When you want to show a value but skip processing it after submission the `:writeable` option is your friend.

```ruby
class ProfileForm < Reform::Form
  property :country, writeable: false
```

This time reform will query the model for the value by calling `model.country`.

You want to use this to display an initial value or to further process this field with JavaScript. However, after submission, the field is no longer considered: it won't be written to the model when saving.

It is still readable in the nested hash and through the form itself.

```ruby
form.save do |nested|
  nested[:country] #=> "Australia"
```

### Write-Only Fields

A third alternative is to hide a field's value but write it to the database when syncing. This can be achieved using the `:readable` option.

```ruby
property :credit_card_number, readable: false
```

## Validations From Models

Sometimes when you still keep validations in your models (which you shouldn't) copying them to a form might not feel right. In that case, you can let Reform automatically copy them.

```ruby
class SongForm < Reform::Form
  property :title

  extend ActiveModel::ModelValidations
  copy_validations_from Song
end
```

Note how `copy_validations_from` copies over the validations allowing you to stay DRY.

This also works with Composition.

```ruby
class SongForm < Reform::Form
  include Composition
  # ...

  extend ActiveModel::ModelValidations
  copy_validations_from song: Song, band: Band
end
```

Be warned that we _do not_ encourage copying validations. You should rather move validation code into forms and not work on your model directly anymore.

## Agnosticism: Mapping Data

Reform doesn't really know whether it's working with a PORO, an `ActiveRecord` instance or a `Sequel` row.

When rendering the form, reform calls readers on the decorated model to retrieve the field data (`Song#title`, `Song#length`).

When syncing a submitted form, the same happens using writers. Reform simply calls `Song#title=(value)`. No knowledge is required about the underlying database layer.

The same applies to saving: Reform will call `#save` on the main model and nested models.

Nesting forms only requires readers for the nested properties as `Album#songs`.


## Rails Integration

Check out [@gogogarret](https://twitter.com/GoGoGarrett/)'s [sample Rails app](https://github.com/gogogarrett/reform_example) using Reform.

Rails and Reform work together out-of-the-box.

However, you should know about two things.

1. In case you explicitely _don't_ want to have automatic support for `ActiveRecord` or `Mongoid` and form builder: `require reform/form`, only.
2. In some setups around Rails 4 the `Form::ActiveRecord` module is not loaded properly, usually triggering a `NoMethodError` saying `undefined method 'model'`. If that happened to you, `require 'reform/rails'` manually at the bottom of your `config/application.rb`.
3. Mongoid form gets loaded with the gem if `Mongoid` constant is defined.


## ActiveRecord Compatibility

Reform provides the following `ActiveRecord` specific features. They're mixed in automatically in a Rails/AR setup.

 * Uniqueness validations. Use `validates_uniqueness_of` in your form.

As mentioned in the [Rails Integration](https://github.com/apotonick/reform#rails-integration) section some Rails 4 setups do not properly load.

You may want to include the module manually then.

```ruby
class SongForm < Reform::Form
  include Reform::Form::ActiveRecord
```

## Mongoid Compatibility

Reform provides the following `Mongoid` specific features. They're mixed in automatically in a Rails/Mongoid setup.

 * Uniqueness validations. Use `validates_uniqueness_of` in your form.

You may want to include the module manually then.

```ruby
class SongForm < Reform::Form
  include Reform::Form::Mongoid
```

## Uniqueness Validation

Both ActiveRecord and Mongoid modules will support "native" uniqueness support from the model class when you use `validates_uniqueness_of`. They will provide options like `:scope`, etc.

You're encouraged to use Reform's non-writing `unique: true` validation, though. [Learn more](http://trailblazerb.org/gems/reform/validation.html)

## ActiveModel Compliance

Forms in Reform can easily be made ActiveModel-compliant.

Note that this step is _not_ necessary in a Rails environment.

```ruby
class SongForm < Reform::Form
  include Reform::Form::ActiveModel
end
```

If you're not happy with the `model_name` result, configure it manually via `::model`.

```ruby
class CoverSongForm < Reform::Form
  include Reform::Form::ActiveModel

  model :song
end
```

`::model` will configure ActiveModel's naming logic. With `Composition`, this configures the main model of the form and should be called once.

This is especially helpful when your framework tries to render `cover_song_path` although you want to go with `song_path`.


## FormBuilder Support

To make your forms work with all the form gems like `simple_form` or Rails `form_for` you need to include another module.

Again, this step is implicit in Rails and you don't need to do it manually.

```ruby
class SongForm < Reform::Form
  include Reform::Form::ActiveModel
  include Reform::Form::ActiveModel::FormBuilderMethods
end
```

### Simple Form

If you want full support for `simple_form` do as follows.

```ruby
class SongForm < Reform::Form
  include ActiveModel::ModelReflections
```

Including this module will add `#column_for_attribute` and other methods need by form builders to automatically guess the type of a property.

## Validations For File Uploads

In case you're processing uploaded files with your form using CarrierWave, Paperclip, Dragonfly or Paperdragon we recommend using the awesome [file_validators](https://github.com/musaffa/file_validators) gem for file type and size validations.

```ruby
class SongForm < Reform::Form
  property :image

  validates :image, file_size: {less_than: 2.megabytes},
    file_content_type: {allow: ['image/jpeg', 'image/png', 'image/gif']}
```

## Multiparameter Dates

Composed multi-parameter dates as created by the Rails date helper are processed automatically when `multi_params: true` is set for the date property and the `MultiParameterAttributes` feature is included. As soon as Reform detects an incoming `release_date(i1)` or the like it is gonna be converted into a date.

```ruby
class AlbumForm < Reform::Form
  feature Reform::Form::ActiveModel::FormBuilderMethods
  feature Reform::Form::MultiParameterAttributes

  collection :songs do
    feature Reform::Form::ActiveModel::FormBuilderMethods
    property :title
    property :release_date, :multi_params => true
    validates :title, :presence => true
  end
end
```

Note that the date will be `nil` when one of the components (year/month/day) is missing.


## Security

By explicitely defining the form layout using `::property` there is no more need for protecting from unwanted input. `strong_parameter` or `attr_accessible` become obsolete. Reform will simply ignore undefined incoming parameters.


## Nesting Without Inline Representers

When nesting form, you usually use a so-called inline form doing `property :song do .. end`.

Sometimes you want to specify an explicit form rather than using an inline form. Use the `form:` option here.

```ruby
property :song, form: SongForm
```

The nested `SongForm` is a stand-alone form class you have to provide.


## Default Values For Presentation

In case you want to change a value for presentation or provide a default value, override the reader. This is only considered when the form is rendered (e.g. in `form_for`).

```ruby
class SongForm < Reform::Form
  property :genre

  def genre
    super || 'Punkrock'
  end
end
```

This will now be used when rendering the view.

```haml
= f.input :genre # calls form.genre which provides default.
```

## Dirty Tracker

Every form tracks changes in `#validate` and allows to check if a particular property value has changed using `#changed?`.

```ruby
form.title => "Button Up"

form.validate("title" => "Just Kiddin'")
form.changed?(:title) #=> true
```

When including `Sync::SkipUnchanged`, the form won't assign unchanged values anymore in `#sync`.


## Deserializing and Population

A form object is just a twin. In `validate`, a representer is used to deserialize the incoming hash and populate the form twin graph. This means, you can use any representer you like and process data like JSON or XML, too.

Representers can be inferred from the contract automatically using `Disposable::Schema`. You may then extend your representer with hypermedia, etc. in order to render documents. Check out the Trailblazer book (chapter Hypermedia APIs) for a full explanation.

You can even write your own deserializer code in case you dislike Representable.

```ruby
class AlbumForm < Reform::Form
  # ..

  def deserialize!(document)
    hash = YAML.parse(document)

    self.title  = hash[:title]
    self.artist = Artist.new if hash[:artist]
  end
end
```

The decoupling of deserializer and form object is one of the main reasons I wrote Reform 2.


## Undocumented Features

_(Please don't read this section!)_

### Skipping Properties when Validating

In `#validate`, you can ignore properties now using `:skip_if` for deserialization.

```ruby
property :hit, skip_if: lambda { |fragment, *| fragment["title"].blank? }
```

This works for both properties and nested forms. The property will simply be ignored when deserializing, as if it had never been in the incoming hash/document.

For nested properties you can use `:skip_if: :all_blank` as a macro to ignore a nested form if all values are blank.

Note that this still runs validations for the property, though.

### Prepopulating Forms

Docs: http://trailblazerb.org/gems/reform/prepopulator.html

When rendering a new form for an empty object, nested forms won't show up. The [Trailblazer book, chapter 5](https://leanpub.com/trailblazer), discusses this in detail.

You can use the `:prepopulator` option to configure how to populate a nested form (this also works for scalar properties).

```ruby
property :song, prepopulator: ->(options) { self.song = Song.new } do
  # ..
end
```

This option is only executed when being instructed to do so, using the `#prepopulate!` method.

```ruby
form.prepopulate!
```

You can also pass options to `#prepopulate`.

Only do this for forms that are about to get rendered, though.

Collections and partial collection population is covered in chapter 5.


### Populator

You can run your very own populator logic if you're keen (and you know what you're doing).

```ruby
class AlbumForm < Reform::Form
  # ...

  collection :songs, populator: lambda { |fragment, args| args.binding[:form].new(Song.find fragment[:id]) } do
    # ..
  end
```

### Property Inflections

When rendering a form you might need to access the options you provided to `property`.

```ruby
property :title, type: String
```

You can do this using `#options_for`.

```ruby
form.options_for(:title) # => {:readable=>true, :coercion_type=>String}
```

Note that Reform renames some options (e.g. `:type` internally becomes `:coercion_type`). Those names are private API and might be changed without deprecation. You better test rendering logic in a unit test to make sure you're forward-compatible.

## Support

If you run into any trouble chat with us on irc.freenode.org#trailblazer.


## Maintainers

[Nick Sutterer](https://github.com/apotonick)
[Garrett Heinlen](https://github.com/gogogarrett)


### Attributions!!!

Great thanks to [Blake Education](https://github.com/blake-education) for giving us the freedom and time to develop this project in 2013 while working on their project.
