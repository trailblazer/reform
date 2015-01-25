# Reform

Decouple your models from forms. Reform gives you a form object with validations and nested setup of models. It is completely framework-agnostic and doesn't care about your database.

Although reform can be used in any Ruby framework, it comes with [Rails support](#rails-integration), works with [simple_form and other form gems](#formbuilder-support), allows nesting forms to implement [has_one](#nesting-forms-1-1-relations) and [has_many](#nesting-forms-1-n-relations) relationships, can [compose a form](#compositions) from multiple objects and gives you [coercion](#coercion).

<a href="https://leanpub.com/trailblazer">
![](https://raw.githubusercontent.com/apotonick/trailblazer/master/doc/trb.jpg)
</a>

Reform is part of the [Trailblazer project](https://github.com/apotonick/trailblazer). Please [buy my book](https://leanpub.com/trailblazer) to support the development and learn everything about Reform. Currently the book discusses:

* Form objects, the DSL and basic API (chapter 2 and 3)
* Basic validations and rendering forms (chapter 3)
* Nested forms, prepopulating and validation populating and pre-selecting values (chapter 5)

More chapters are coming!


## Installation

Add this line to your Gemfile:

```ruby
gem 'reform'
```

## Nomenclature

Reform comes with two base classes.

* `Form` is what made you come here - it gives you a form class to handle all validations, wrap models, allow rendering with Rails form helpers, simplifies saving of models, and more.
* `Contract` gives you a sub-set of `Form`: [this class](#contracts) is meant for API validation where already populated models get validated without having to maintain validations in the model classes.


## Defining Forms

You're working at a famous record label and your job is archiving all the songs, albums and artists. You start with a form to populate your `songs` table.

```ruby
class SongForm < Reform::Form
  property :title
  property :length

  validates :title, presence: true
  validates :length, numericality: true
end
```

Define your form's fields using `::property`. Validations no longer go into the model, but into the form.

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

After explicitely defining your fields, you're ready to use the form.

## The API

Forms have a ridiculously simple API with only a handful of public methods.

1. `#initialize` always requires a model that the form represents.
2. `#validate(params)` updates the form's fields with the input data (only the form, _not_ the model) and then runs all validations. The return value is the boolean result of the validations.
3. `#errors` returns validation messages in a classy ActiveModel style.
4. `#sync` writes form data back to the model. This will only use setter methods on the model(s).
5. `#save` (optional) will call `#save` on the model and nested models. Note that this implies a `#sync` call.

In addition to the main API, forms expose accessors to the defined properties. This is used for rendering or manual operations.


## Setup

In your controller you'd create a form instance and pass in the models you want to work on.

```ruby
class SongsController
  def new
    @form = SongForm.new(Song.new)
  end
```

You can also setup the form for editing existing items.

```ruby
class SongsController
  def edit
    @form = SongForm.new(Song.find(1))
  end
```

Reform will read property values from the model in setup. Given the following form class.

```ruby
class SongForm < Reform::Form
  property :title
```

Internally, this form will call `song.title` to populate the title field.

If you, for whatever reasons, want to use a different public name, use `:from`.

```ruby
class SongForm < Reform::Form
  property :name, from: :title
```

This will still call `song.title` but expose the attribute as `name`.

## Rendering Forms

Your `@form` is now ready to be rendered, either do it yourself or use something like Rails' `#form_for`, `simple_form` or `formtastic`.

```haml
= form_for @form do |f|

  = f.input :name
  = f.input :title
```

Nested forms and collections can be easily rendered with `fields_for`, etc. Just use Reform as if it would be an ActiveModel instance in the view layer.

Note that you have a mechanism to [prepopulate forms](#prepopulating-forms) for rendering.

## Validation

After a form submission, you want to validate the input.

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
    @form.save  #=> populates song with incoming data
                #   by calling @form.song.title= and @form.song.length=.
```

This will sync the data to the model and then call `song.save`.

Sometimes, you need to do stuff manually.


## Saving Forms Manually

Calling `#save` with a block doesn't do anything but providing you a nested hash with all the validated input. This allows you to implement the saving yourself.

The block parameter is a nested hash of the form input.

```ruby
  @form.save do |hash|
    hash      #=> {title: "Rio", length: "366"}

    Song.create(hash)
  end
```

You can always access the form's model. This is helpful when you were using populators to set up objects when validating.

```ruby
  @form.save do |nested|
    album = @form.model

    album.update_attributes(nested[:album])
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


## Nesting Forms: 1-1 Relations

Songs have artists to compose them. Let's say your `Song` model would implement that as follows.

```ruby
class Song < ActiveRecord::Base
  has_one :artist
end
```

The edit form should allow changing data for artist and song.

```ruby
class SongForm < Reform::Form
  property :title
  property :length

  property :artist do
    property :name

    validates :name, presence: true
  end

  #validates :title, ...
end
```

See how simple nesting forms is? By passing a block to `::property` you can define another form nested into your main form.


### has_one: Setup

This setup's only requirement is having a working `Song#artist` reader.

```ruby
class SongsController
  def edit
    song = Song.find(1)
    song.artist #=> <0x999#Artist title="Duran Duran">

    @form = SongForm.new(song)
  end
```

### has_one: Rendering

When rendering this form you could use the form's accessors manually.

```haml
= text_field :title,         @form.title
= text_field "artist[name]", @form.artist.name
```

Or use something like `#fields_for` in a Rails environment.

```haml
= form_for @form do |f|
  = f.text_field :title
  = f.text_field :length

  = f.fields_for :artist do |a|
    = a.text_field :name
```

### has_one: Processing

The block form of `#save` would give you the following data.

```ruby
@form.save do |nested|

  nested #=> {title:  "Hungry Like The Wolf",
         #    artist: {name: "Duran Duran"}}
end
```

Supposed you use reform's automatic save without a block, the following assignments would be made.

```ruby
form.song.title       = "Hungry Like The Wolf"
form.song.artist.name = "Duran Duran"
form.song.save
```

## Nesting Forms: 1-n Relations

Reform also gives you nested collections.

Let's have Albums with songs!

```ruby
class Album < ActiveRecord::Base
  has_many :songs
end
```

The form might look like this.

```ruby
class AlbumForm < Reform::Form
  property :title

  collection :songs do
    property :title

    validates :title, presence: true
  end
end
```

This basically works like a nested `property` that iterates over a collection of songs.

### has_many: Rendering

Reform will expose the collection using the `#songs` method.

```haml
= text_field :title,         @form.title
= text_field "songs[0][title]", @form.songs[0].title
```

However, `#fields_for` works just fine, again.

```haml
= form_for @form do |f|
  = f.text_field :title

  = f.fields_for :songs do |s|
    = s.text_field :title
```

### has_many: Processing

The block form of `#save` will expose the data structures already discussed.

```ruby
@form.save do |nested|

  nested #=> {title: "Rio"
         #   songs: [{title: "Hungry Like The Wolf"},
         #          {title: "Last Chance On The Stairways"}]
end
```


## Nesting Configuration

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


### Populating Forms For Validation

With a complex nested setup it can sometimes be painful to setup the model object graph.

Let's assume you rendered the following form.

```ruby
@form = AlbumForm.new(Album.new(songs: [Song.new, Song.new]))
```

This will render two nested forms to create new songs.

When **validating**, you're supposed to setup the very same object graph, again. Reform has no way of remembering what the object setup was like a request ago.

So, the following code will fail.

```ruby
@form = AlbumForm.new(Album.new).validate(params[:album])
```

However, you can advise Reform to setup the correct objects for you.

```ruby
class AlbumForm < Reform::Form
  # ...

  collection :songs, populate_if_empty: Song do
    # ..
  end
```

This works for both `property` and `collection` and instantiates `Song` objects where they're missing when calling `#validate`.

If you want to create the objects yourself, because you're smarter than Reform, do it with a lambda.

```ruby
class AlbumForm < Reform::Form
  # ...

  collection :songs, populate_if_empty: lambda { |fragment, args| Song.new } do
    # ..
  end
```


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

Here's how the block parameters look like.

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

1. In case you explicitely _don't_ want to have automatic support for `ActiveRecord` and form builder: `require reform/form`, only.
2. In some setups around Rails 4 the `Form::ActiveRecord` module is not loaded properly, usually triggering a `NoMethodError` saying `undefined method 'model'`. If that happened to you, `require 'reform/rails'` manually at the bottom of your `config/application.rb`.

## ActiveRecord Compatibility

Reform provides the following `ActiveRecord` specific features. They're mixed in automatically in a Rails/AR setup.

 * Uniqueness validations. Use `validates_uniqueness_of` in your form.

As mentioned in the [Rails Integration](https://github.com/apotonick/reform#rails-integration) section some Rails 4 setups do not properly load.

You may want to include the module manually then.

```ruby
class SongForm < Reform::Form
  include Reform::Form::ActiveRecord
```


## ActiveModel Compliance

Forms in Reform can easily be made ActiveModel-compliant.

Note that this step is _not_ necessary in a Rails environment.

```ruby
class SongForm < Reform::Form
  include Reform::Form::ActiveModel
end
```

If you're not happy with the `model_name` result, configure it manually.

```ruby
class CoverSongForm < Reform::Form
  include Reform::Form::ActiveModel

  model :song
end
```

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
  include ModelReflections
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

Composed multi-parameter dates as created by the Rails date helper are processed automatically. As soon as Reform detects an incoming `release_date(i1)` or the like it is gonna be converted into a date.

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


## Overriding Setters For Coercion

When "real" coercion is too much and you simply want to convert incoming data yourself, override the setter.

```ruby
class SongForm < Reform::Form
  property :title

  def title=(v)
    super(v.upcase)
  end
```

This will capitalize the title _after_ calling `form.validate` but _before_ validation happens. Note that you can use `super` to call the original setter.


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


## Dynamically Syncing And Saving Properties

Both `#sync` and `#save` can be configured to run a dynamical lambda per property.

The `sync:` option allows to statically add a lambda to a property.

```ruby
property :title, sync: lambda { |value, options| model.set_title(value) }
```

Instead of running Reform's built-in sync for this property the block is run.

You can also provide the sync lambda at run-time.

```ruby
form.sync(title: lambda { |value, options| form.model.title = "HOT: #{value}" })
```

This block is run in the caller's context allowing you to access environment variables. Note that the dynamic sync happens _before_ save, so the model id may be unavailable.

You can do the same for saving.

```ruby
form.save(title: lambda { |value, options| form.model.title = "#{form.model.id} --> #{value}" })
```
Again, this block is run in the caller's context.

The two features are an excellent way to handle file uploads without ActiveRecord's horrible callbacks.


## Undocumented Features

_(Please don't read this section!)_


### Prepopulating Forms

When rendering a new form for an empty object, nested forms won't show up. The [Trailblazer book, chapter 5](https://leanpub.com/trailblazer), discusses this in detail.

You can use the `:prepopulate` option to configure how to populate a nested form (this also works for scalar properties).

```ruby
property :song, prepopulate: ->(*) { Song.new } do
  # ..
end
```

This option is only executed when being instructed to do so, using the `#prepopulate!` method.

```ruby
form.prepopulate!
```

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
