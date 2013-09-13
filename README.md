# Reform

Decouple your models from forms. Reform gives you a form object with validations and nested setup of models. It is completely framework-agnostic and doesn't care about your database.

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

  = fields_for :artist do |a|
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

  = fields_for :songs do |s|
    = s.text_field :title
```

### has_many: Processing

The block form of `#save` will expose the data structures already discussed.

```ruby
@form.save do |data, nested|
  data.title #=> "Rio"
  data.songs.first.title #=> "Hungry Like The Wolf"

  nested #=> {title: "Rio"
              songs: [{title: "Hungry Like The Wolf"},
                     {title: "Last Chance On The Stairways"}]
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
              song:  {title: "Rio"}
              label: {city: "London"}
             }
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


## Agnosticism: Mapping Data

Reform doesn't really know whether it's working with a PORO, an `ActiveRecord` instance or a `Sequel` row.

When rendering the form, reform calls readers on the decorated model to retrieve the field data (`Song#title`, `Song#length`).

When saving a submitted form, the same happens using writers. Reform simply calls `Song#title=(value)`. No knowledge is required about the underlying database layer.

Nesting forms only requires readers for the nested properties as `Album#songs`.


## Rails Integration

[A sample Rails app using Reform.](https://github.com/gogogarrett/reform_example)

Reform offers ActiveRecord support to easily make this accessible in Rails based projects. You simply `include Reform::Form::ActiveRecord` in your form object and the Rails specific code will be handled for you. This happens by adding behaviour to make the form ActiveModel-compliant. Note that this module will also work with other ORMs like Datamapper.

### Simple Integration
#### Form Class

You have to include a call to `model` to specify which is the main object of the form.

```ruby
require 'reform/rails'

class UserProfileForm < Reform::Form
  include DSL
  include Reform::Form::ActiveRecord

  property :email,        on: :user
  properties [:gender, :age],   on: :profile

  model :user

  validates :email, :gender, presence: true
  validates :age, numericality: true
  validates_uniqueness_of :email
end
```

Basically, `model :user` tells Reform to use the `:user` object in the composition as the form main object while using `"user"` as the form name (needed for URL computation). If you want to change the form name let Reform know.

```ruby
  model :singer, :on => :user # form name is "singer" whereas main object is `:user` in composition.
```


#### View Form

The form becomes __very__ dumb as it knows nothing about the backend assocations or data binding to the database layer.  This simply takes input and passes it along to the controller as it should.

```erb
<%= form_for @form do |f| %>
  <%= f.email_field :email %>
  <%= f.input :gender %>
  <%= f.number_field :age %>
  <%= f.submit %>
<% end %>
```

#### Controller

In the controller you can easily create helpers to build these form objects for you.  In the create and update actions Reform allows you total control of what to do with the data being passed via the form. How you interact with the data is entirely up to you.

```ruby
class UsersController < ApplicationController

  def create
    @form = create_new_form
    if @form.validate(params[:user])
      @form.save do |data, map|
        new_user = User.new(map[:user])
        new_user.build_user_profile(map[:profile])
        new_user.save!
      end
    end
  end


  private
  def create_new_form
    UserProfileForm.new(user: User.new, profile: UserProfile.new)
  end
end
```

__Note__: this can also be used for the update action as well.

## Using Your Models In Validations

Sometimes you want to access your database in a validation. You can access the models using the `#model` accessor in the form.

```ruby
class ArtistForm < Reform::Form
  property :name

  validate "name_correct?"

  def name_correct?
    errors.add :name, "#{name} is stupid!" if model.artist.stupid_name?(name)
  end
end
```

## ActiveModel compliance



## Security

By explicitely defining the form layout using `::property` there is no more need for protecting from unwanted input. `strong_parameter` or `attr_accessible` become obsolete. Reform will simply ignore undefined incoming parameters.

## Support

If you run into any trouble chat with us on irc.freenode.org#trailblazer.

## Maintainers

[Nick Sutterer](https://github.com/apotonick)

[Garrett Heinlen](https://github.com/gogogarrett)

### Attributions!!!

Great thanks to [Blake Education](https://github.com/blake-education) for giving us the freedom and time to develop this project while working on their project.
