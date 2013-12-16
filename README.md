# Reform

Decouple your models from forms. Reform gives you a form object with validations and nested setup of models. It is completely framework-agnostic and doesn't care about your database.

Although reform can be used in any Ruby framework, it comes with [Rails support](#rails-integration), works with [simple_form and other form gems](#formbuilder-support), allows nesting forms to implement [has_one](#nesting-forms-1-1-relations) and [has_many](#nesting-forms-1-n-relations) relationships, can [compose a form](#compositions) from multiple objects and gives you [coercion](#coercion).


## Installation

Add this line to your Gemfile:

```ruby
gem 'reform'
```

## Defining Forms

You're working at a famous record label and your job is archiving all the songs, albums and artists. You start with a form to populate your `songs` table.

```ruby
class SongForm < Reform::Form
  property :title
  property :length

  validates :title,  presence: true
  validates :length, numericality: true
end
```

To add fields to the form use the `::property` method. Also, validations no longer go into the model but sit in the form.


## Using Forms

In your controller you'd create a form instance and pass in the models you wanna work on.

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

## Rendering Forms

Your `@form` is now ready to be rendered, either do it yourself or use something like Rails' `#form_for`, `simple_form` or `formtastic`.

```haml
= form_for @form do |f|

  = f.input :name
  = f.input :title
```

## Validating Forms

After a form submission, you wanna validate the input.

```ruby
class SongsController
  def create
    @form = SongForm.new(Song.new)

    #=> params: {song: {title: "Rio", length: "366"}}

    if @form.validate(params[:song])
```

Reform uses the validations you provided in the form - and nothing else.


## Saving Forms

We provide a bullet-proof way to save your form data: by letting _you_ do it!

```ruby
  if @form.validate(params[:song])

    @form.save do |data, nested|
      data.title  #=> "Rio"
      data.length #=> "366"

      nested      #=> {title: "Rio"}

      Song.create(nested)
    end
```

While `data` gives you an object exposing the form property readers, `nested` is a hash reflecting the nesting structure of your form. Note how you can use arbitrary code to create/update models - in this example, we used `Song::create`.

To push the incoming data to the models directly, call `#save` without the block.

```ruby
    @form.save  #=> populates song with incoming data
                #   by calling @form.song.title= and @form.song.length=.
```

Think of `@form.save` as a sync operation where the submitted data is written to your models using public setters.

Note that this does _not_ call `save` on your models per default: this only happens in an ActiveRecord environment or when `Form::ActiveRecord` is mixed in (learn more [here](https://github.com/apotonick/reform#activerecord-compatibility)).



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
= form_for @form |f|
  = f.text_field :title
  = f.text_field :length

  = f.fields_for :artist do |a|
    = a.text_field :name
```

### has_one: Processing

The block form of `#save` would give you the following data.

```ruby
@form.save do |data, nested|
  data.title #=> "Hungry Like The Wolf"
  data.artist.name #=> "Duran Duran"

  nested #=> {title:  "Hungry Like The Wolf",
         #    artist: {name: "Duran Duran"}}
end
```

Supposed you use reform's automatic save without a block, the following assignments would be made.

```ruby
form.song.title       = "Hungry Like The Wolf"
form.song.artist.name = "Duran Duran"
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
= form_for @form |f|
  = f.text_field :title

  = f.fields_for :songs do |s|
    = s.text_field :title
```

### has_many: Processing

The block form of `#save` will expose the data structures already discussed.

```ruby
@form.save do |data, nested|
  data.title #=> "Rio"
  data.songs.first.title #=> "Hungry Like The Wolf"

  nested #=> {title: "Rio"
         #   songs: [{title: "Hungry Like The Wolf"},
         #          {title: "Last Chance On The Stairways"}]
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

  validates :title, :city, presence: true
end
```

Note that reform needs to know about the owner objects of properties. You can do so by using the `on:` option.

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
@form.save do |data, nested|
  data.title #=> "Rio"
  data.city  #=> "London"

  nested #=> {
         #   song:  {title: "Rio"}
         #   label: {city: "London"}
         #   }
end
```

## Coercion

Often you want incoming form data to be converted to a type, like timestamps. Reform uses [virtus](https://github.com/solnic/virtus) for coercion, the DSL is seamlessly integrated into Reform with the `:type` option.

Be sure to add `virtus` to your Gemfile.

```ruby
require 'reform/form/coercion'

class SongForm < Reform::Form
  include Coercion

  property :written_at, type: DateTime
end

@form.save do |data, nested|
  data.written_at #=> <DateTime XXX>
```

## Virtual Attributes

Virtual fields come in handy when there's no direct mapping to a model attribute or when you plan on displaying but not processing a value.


### Empty Fields

Often, fields like `password_confirmation` shouldn't be retrieved from the model. Reform comes with the `:empty` option for that.

```ruby
class PasswordForm < Reform::Form
  property :password
  property :password_confirmation, :empty => true
```

Here, the model won't be queried for a `password_confirmation` field when creating and rendering the form. Likewise, when saving the form, the input value is not written to the decorated model. It is only readable in validations and when saving the form.

```ruby
form.validate("password" => "123", "password_confirmation" => "321")

form.password_confirmation #=> "321"
```

The nested hash in the block-`#save` provides the same value.

```ruby
form.save do |f, nested|
  nested[:password_confirmation] #=> "321"
```

### Read-Only Fields

Almost identical, the `:virtual` option makes fields read-only. Say you wanna show a value, but not process it after submission, this option is your friend.

```ruby
class ProfileForm < Reform::Form
  property :country, :virtual => true
```

This time reform will query the model for the value by calling `model.country`.

You want to use this to display an initial value or to further process this field with JavaScript. However, after submission, the field is no longer considered: it won't be written to the model when saving.

It is still readable in the nested hash and through the form itself.

```ruby
form.save do |f, nested|
  nested[:country] #=> "Australia"

  f.country #=> "Australia"
```


## Agnosticism: Mapping Data

Reform doesn't really know whether it's working with a PORO, an `ActiveRecord` instance or a `Sequel` row.

When rendering the form, reform calls readers on the decorated model to retrieve the field data (`Song#title`, `Song#length`).

When saving a submitted form, the same happens using writers. Reform simply calls `Song#title=(value)`. No knowledge is required about the underlying database layer.

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
 * Calling `Form#save` will explicitely call `save` on your model (added in 0.2.1) which will usually trigger a database insertion or update.


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

This is especially helpful when your framework tries to render `cover_song_path` although you wanna go with `song_path`.


## FormBuilder Support

To make your forms work with all the form gems like `simple_form` or Rails `form_for` you need to include another module.

Again, this step is implicit in Rails and you don't need to do it manually.

```ruby
class SongForm < Reform::Form
  include Reform::Form::ActiveModel
  include Reform::Form::ActiveModel::FormBuilderMethods
end
```

## Multiparameter Dates

Composed multi-parameter dates as created by the Rails date helper are processed automatically. As soon as Reform detects an incoming `release_date(i1)` or the like it is gonna be converted into a date.

Note that the date will be `nil` when one of the components (year/month/day) is missing.


## Security

By explicitely defining the form layout using `::property` there is no more need for protecting from unwanted input. `strong_parameter` or `attr_accessible` become obsolete. Reform will simply ignore undefined incoming parameters.


## Additional Features

### Nesting Without Inline Representers

When nesting form, you usually use a so-called inline form doing `property :song do .. end`.

Sometimes you wanna specify an explicit form rather than using an inline form. Use the `form:` option here.

```ruby
property :song, form: SongForm`
```

The nested `SongForm` is a stand-alone form class you have to provide.


## Support

If you run into any trouble chat with us on irc.freenode.org#trailblazer.


## Maintainers

[Nick Sutterer](https://github.com/apotonick)

[Garrett Heinlen](https://github.com/gogogarrett)


### Attributions!!!

Great thanks to [Blake Education](https://github.com/blake-education) for giving us the freedom and time to develop this project while working on their project.
