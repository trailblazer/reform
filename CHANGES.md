## 2.3.3

* Rename validation option for dry-v 1+ to `contract` instead of `schema`

## 2.3.2

* Fix Validation block option :form incorrectly memoized between tests

## 2.3.1
* With dry-validation 1.5 the form is always injected. Just add option :form to access it in the schema.
* Removed global monkey patching of Dry::Schema::DSL
* Tests in ruby 2.7

## 2.3.0

You can upgrade from 2.2.0 without worries.

* Require Representable 3.0.0 and **removed Representable 2.4 deprecation code**.
* Require Disposable 0.4.0 which fixes issues with `nil` field values, `sync {}` and dry-validation.
* Fix boolean coercion.
* Allow using `:populator` classes marked with `Uber::Callable`.
* Introduce `parse: false` as a shortcut for `deserialzer: { writeable: false}`. Thanks to @pabloh for insisting on this handy change.
* Memoize the deserializer instance on the class level via `::deserializer`. This saves the inferal of a deserializing representer and speeds up following calls by 130%.
* Deprecated positional arguments for `validation :default, options: {}`. New API: `validation name: :default, **`.
* Reform now maintains a generic `Dry::Schema` class for global schema configuration. Can be overridden via `::validation`.
* When validating with dry-validation, we now pass a symbolized hash. We also replaced `Dry::Validation::Form` with `Schema` which won't coerce values where it shouldn't.
* [private] `Group#call` API now is: `call(form, errors)`.
* Modify `Form#valid?` - simply calls `validate({})`.
* In `:if` for validation groups, you now get a hash of result objects, not just true/false.
* Allow adding a custom error AFTER validate has been already called

Compatibility with `dry-validation` with 1.x:
* [CHANGE] seems like "custom" predicate are not supported by `dry-schema` anymore or better the same result is reached using the `rule` method:
  Something like this:
  ```ruby
  validation do
    def a_song?(value)
       value == :really_cool_song
    end

    required(:songs).filled(:a_song?)
  end
  ```
  will be something like:
  ```ruby
  validation do
    required(:songs).filled

    rule(:songs) do
      key.failure(:a_song?) unless value == :really_cool_song
    end
  end
  ```
* [BREAKING] inheriting/merging/overriding schema/rules is not supported by `dry-v` so the `inherit:` option is **NOT SUPPORTED** for now. Also extend a `schema:` option using a block is **NOT SUPPORTED** for now. Possible workaround is to use reform module to compose different validations but this won't override existing validations but just merge them

## 2.2.4

* You can now use any object with `call` as a populator, no need to `include Uber::Callable` anymore. This is because we have only three types and don't need a `is_a?` or `respond_to?` check.
* Use `declarative-option` and loosen `uber` dependency.

## 2.2.3

* Add `Form#call` as an alias for `validate` and the `Result` object.

## 2.2.2

* Loosen `uber` dependency.

## 2.2.1

* Fix `Contract::Properties`. Thanks @simonc. <3

## 2.2.0

* Remove `reform/rails`. This is now handled via the `reform-rails` gem which you have to bundle.
* For coercion, we now use [dry-types](https://github.com/dry-rb/dry-types) as a replacement for the deprecated virtus. You have to change to dry-types' constants, e.g. `type: Types::Form::Bool`.
* Use disposable 0.3.0. This gives us the long-awaited `nilify: true` option.

####### TODO: fix Module and coercion Types::*

## 2.1.0

You should be able to upgrade from 2.0 without any code changes.

### Awesomeness

* You can now have `:populator` for scalar properties, too. This allows "parsing code" per property which is super helpful to structure your deserialization.
* `:populator` can be a method name, as in `populator: :populate_authors!`.
* Populators can now skip deserialization of a nested fragment using `skip!`. [Learn more here](http://trailblazer.to/gems/reform/populator.html#skip).
* Added support for dry-validation as a future replacement for ActiveModel::Validation. Note that this is still experimental, but works great.
* Added validation groups.

### Changes

* All lambda APIs change (with deprecation): `populator: ->(options)` or `->(fragment:, model:, **o)` where we only receive one hash instead of a varying number or arguments. This is pretty cool and should be listed under _Awesomeness_.
* `ActiveModel::Validator` prevents Rails from adding methods to it. This makes `acceptance` and `confirmation` validations work properly.

### Notes

* Please be warned that we will drop support for `ActiveModel::Validations` from 2.2 onwards. Don't worry, it will still work, but we don't want to work with it anymore.

## 2.0.5

* `ActiveModel::Validator` now delegates all methods properly to the form. It used to crashed with properties called `format` or other private `Object` methods.
* Simpleform will now properly display fields as required, or not (by introducion `ModelReflections::validators_on`).
* The `:default` option is not copied into the deserializer anymore from the schema. This requires disposable 0.1.11.

## 2.0.4

* `#sync` and `#save` with block now provide `HashWithIndifferentAccess` in Rails.

## 2.0.3

* `Form#valid?` is private now. Sorry for the inconvenience, but this has never been documented as public. Reason is that the only entry point for validation is `#validate` to give the form as less public API as possible and minimize misunderstandings.

    The idea is that you set up the object graph before/while `#validate` and then invoke the validators once.
* Fixed AM to find proper i18n for error messages. This happens by injecting the form's `model_name` into the `Validator` object in ActiveModel.

## 2.0.2

* Fix `unique: true` validation in combination with `Composition`.
* Use newest Disposable 0.1.9 which does not set `:pass_options` anymore.

## 2.0.1

* Fix `ActiveModel::Validations` where translations in custom validations would error. This is now handled by delegating back to the `Validator` object in Reform.

## 2.0.0

* The `::reform_2_0!` is no longer there. Guess why.
* Again: `:empty` doesn't exist anymore. You can choose from `:readable`, `:writeable` and `:virtual`.
* When using `:populator` the API to work against the form has changed.
    ```ruby
    populator: lambda { |fragment, index, args|
      songs[index] or songs[index] = args.binding[:form].new(Song.new)
    }
    ```

   is now

   ```ruby
   populator: lambda { |fragment, index, args|
     songs[index] or songs.insert(index) = Song.new
   }
   ```
    You don't need to know about forms anymore, the twin handles that using the [Twin](https://github.com/apotonick/disposable) API..

* `:as` option removed. Use `:from`.
* With `Composition` included, `Form#model` would give you a composition object. You can grab that using `Form#mapper` now.
* `Form#update!` is deprecated. It still works but will remind you to override `#present!` or use pre-populators as [described here](http://trailblazerb.org/gems/reform/prepopulator.html) and in the Trailblazer book, chapter "Nested Forms".
* Forms do not `include ActiveModel::Validations` anymore. This has polluted the entire gem and is not encapsulated in `Validator`. Consider using Lotus Validations instead.
* Validation inheritance with `ActiveModel::Validations` is broken with Rails 3.2 and 4.0. Update Rails or use the `Lotus` validations.

## 2.0.0.rc3

* Fix an annoying bug coming from Rails autoloader with validations and `model_name`.

## 1.2.6

* Added `:prepopulate` to fill out form properties for presentation. Note that you need to call `Form#prepopulate!` to trigger the prepopulation.
* Added support for DateTime properties in forms. Until now, we were ignoring the time part. Thanks to @gdott9 for fixing this.

## 1.2.5

* Added `Form#options_for` to have access to all property options.

## 1.2.4

* Added `Form#readonly?` to find out whether a field is set to writeable. This is helpful for simple_form to display a disabled input field.

    ```ruby
    property :title, writeable: false
    ```

    In the view, you can then use something along the following code.

    ```ruby
    f.input :title, readonly: @form.readonly?(:title)
    ```

## 1.2.3

* Make `ModelReflections` work with simple_form 3.1.0. (#176). It also provides `defined_enums` and `::reflect_on_association` now.
* `nil` values passed into `#validate` will now be written to the model in `#sync` (#175). Formerly, only blank strings and values evaluating to true were considered when syncing. This allows blanking fields of the model as follows.

    ```ruby
    form.validate(title: nil)
    ```
* Calling `Form::reform_2_0!` will now properly inherit to nested forms.

## 1.2.2

* Use new `uber` to allow subclassing `reform_2_0!` forms.
* Raise a better understandable deserialization error when the form is not populated properly. This error is so common that I overcame myself to add a dreaded `rescue` block in `Form#validate`.

## 1.2.1

* Fixed a nasty bug where `ActiveModel` forms with form builder support wouldn't deserialize properly. A million Thanks to @karolsarnacki for finding this and providing an exemplary failing test. <3

## 1.2.0

### Breakage

* Due to countless bugs we no longer include support for simple_form's type interrogation automatically. This allows using forms with non-AM objects. If you want full support for simple_form do as follows.

    ```ruby
    class SongForm < Reform::Form
      include ModelReflections
    ```

    Including this module will add `#column_for_attribute` and other methods need by form builders to automatically guess the type of a property.

* `Form#save` no longer passed `self` to the block. You've been warned long enough. ;)

### Changes

* Renamed `:as` to `:from` to be in line with Representable/Roar, Disposable and Cells. Thanks to @bethesque for pushing this.
* `:empty` is now `:virtual` and `:virtual` is `writeable: false`. It was too confusing and sucked. Thanks to @bethesque, again, for her moral assistance.
* `Form#save` with `Composition` now returns true only if all composite models saved.
* `Form::copy_validations_from` allows copying custom validators now.
* New call style for `::properties`. Instead of an array, it's now `properties :title, :genre`.
* All options are evaluated with `pass_options: true`.
* All transforming representers are now created and stored on class level, resulting in simpler code and a 85% speed-up.

### New Stuff!!!

* In `#validate`, you can ignore properties now using `:skip_if`.

    ```ruby
    property :hit, skip_if: lambda { |fragment, *| fragment["title"].blank? }
    ```

    This works for both properties and nested forms. The property will simply be ignored when deserializing, as if it had never been in the incoming hash/document.

    For nested properties you can use `:skip_if: :all_blank` as a macro to ignore a nested form if all values are blank.
* You can now specify validations right in the `::property` call.

    ```ruby
    property :title, validates: {presence: true}
    ```

    Thanks to @zubin for this brillant idea!

* Reform now tracks which attributes have changed after `#validate`. You can check that using `form.changed?(:title)`.
* When including `Sync::SkipUnchanged`, the form won't try to assign unchanged values anymore in `#sync`. This is extremely helpful when handling file uploads and the like.
* Both `#sync` and `#save` can be configured dynamically now.

    When syncing, you can run a lambda per property.

    ```ruby
    property :title, sync: lambda { |value, options| model.set_title(value) }
    ```

    This won't run Reform's built-in sync for this property.

    You can also provide the sync lambda at run-time.

    ```ruby
    form.sync(title: lambda { |value, options| form.model.title = "HOT: #{value}" })
    ```

    This block is run in the caller's context allowing you to access environment variables.

    Note that the dynamic sync happens _before_ save, so the model id may unavailable.

    You can do the same for saving.

    ```ruby
    form.save(title: lambda { |value, options| form.model.title = "#{form.model.id} --> #{value}" })
    ```
    Again, this block is run in the caller's context.

    The two features are an excellent way to handle file uploads without ActiveRecord's horrible callbacks.

* Adding generic `:base` errors now works. Thanks to @bethesque.

    ```ruby
    errors.add(:base, "You are too awesome!")
    ```

  This will prefix the error with `:base`.
* Need your form to parse JSON? Include `Reform::Form::JSON`, the `#validate` method now expects a JSON string and will deserialize and populate the form from the JSON document.
* Added `Form::schema` to generate a pure representer from the form's representer.
* Added `:readable` and `:writeable` option which allow to skip reading or writing to the model when `false`.

## 1.1.1

* Fix a bug where including a form module would mess up the options has of the validations (under older Rails).
* Fix `::properties` which modified the options hash while iterating properties.
* `Form#save` now returns the result of the `model.save` invocation.
* Fix: When overriding a reader method for a nested form for presentation (e.g. to provide an initial new record), this reader was used in `#update!`. The deserialize/update run now grabs the actual nested form instances directly from `fields`.
* `Errors#to_s` is now delegated to `messages.to_s`. This is used in `Trailblazer::Operation`.

## 1.1.0

* Deprecate first block argument in save. It's new signature is `save { |hash| }`. You already got the form instance when calling `form.save` so there's no need to pass it into the block.
* `#validate` does **not** touch any model anymore. Both single values and collections are written to the model after `#sync` or `#save`.
* Coercion now happens in `#validate`, only.
* You can now define forms in modules including `Reform::Form::Module` to improve reusability.
* Inheriting from forms and then overriding/extending properties with `:inherit` now works properly.
* You can now define methods in inline forms.
* Added `Form::ActiveModel::ModelValidations` to copy validations from model classes. Thanks to @cameron-martin for this fine addition.
* Forms can now also deserialize other formats, e.g. JSON. This allows them to be used as a contract for API endpoints and in Operations in Trailblazer.
* Composition forms no longer expose readers to the composition members. The composition is available via `Form#model`, members via `Form#model[:member_name]`.
* ActiveRecord support is now included correctly and passed on to nested forms.
* Undocumented/Experimental: Scalar forms. This is still WIP.

## 1.0.4

Reverting what I did in 1.0.3. Leave your code as it is. You may override a writers like `#title=` to sanitize or filter incoming data, as in

```ruby
def title=(v)
  super(v.strip)
end
```

This setter will only be called in `#validate`.

Readers still work the same, meaning that

```ruby
def title
  super.downcase
end
```

will result in lowercased title when rendering the form (and only then).

The reason for this confusion is that you don't blog enough about Reform. Only after introducing all those deprecation warnings, people started to contact me to ask what's going on. This gave me the feedback I needed to decide what's the best way for filtering incoming data.

## 1.0.3

* Systematically use `fields` when saving the form. This avoids calling presentational readers that might have been defined by the user.

## 1.0.2

* The following property names are reserved and will raise an exception: `[:model, :aliased_model, :fields, :mapper]`
* You get warned now when overriding accessors for your properties:

    ```ruby
    property :title

    def title
      super.upcase
    end
    ```

    This is because in Reform 1.1, those accessors will only be used when rendering the form, e.g. when doing `= @form.title`. If you override the accessors for presentation, only, you're fine. Add `presentation_accessors: true` to any property, the warnings will be suppressed and everything's gonna work. You may remove `presentation_accessors: true` in 1.1, but it won't affect the form.

    However, if you used to override `#title` or `#title=` to manipulate incoming data, this is no longer working in 1.1. The reason for this is to make Reform cleaner. You will get two options `:validate_processor` and `:sync_processor` in order to filter data when calling `#validate` and when syncing data back to the model with `#sync` or `#save`.

## 1.0.1

* Deprecated model readers for `Composition` and `ActiveModel`. Consider the following setup.
    ```ruby
      class RecordingForm < Reform::Form
        include Composition

        property :title, on: :song
      end
    ```

  Before, Reform would allow you to do `form.song` which returned the song model. You can still do this (but you shouldn't) with `form.model[:song]`.

  This allows having composed models and properties with the same name. Until 1.1, you have to use `skip_accessors: true` to advise Reform _not_ to create the deprecated accessor.

  Also deprecated is the alias accessor as found with `ActiveModel`.
    ```ruby
      class RecordingForm < Reform::Form
        include Composition
        include ActiveModel

        model :hit, on: :song
      end
    ```
  Here, an automatic reader `Form#hit` was created. This is deprecated as

  This is gonna be **removed in 1.1**.


## 1.0.0

* Removed `Form::DSL` in favour of `Form::Composition`.
* Simplified nested forms. You can now do
    ```ruby
    validates :songs, :length => {:minimum => 1}
    validates :hit, :presence => true
    ```
* Allow passing symbol hash keys into `#validate`.
* Unlimited nesting of forms, if you really want that.
* `save` gets called on all nested forms automatically, disable with `save: false`.
* Renaming with `as:` now works everywhere.
* Fixes to make `Composition` work everywhere.
* Extract setup and validate into `Contract`.
* Automatic population with `:populate_if_empty` in `#validate`.
* Remove `#from_hash` and `#to_hash`.
* Introduce `#sync` and make `#save` less smart.

## 0.2.7

* Last release supporting Representable 1.7.
* In ActiveModel/ActiveRecord: The model name is now correctly infered even if the name is something like `Song::Form`.

## 0.2.6

* Maintenance release cause I'm stupid.

## 0.2.5

* Allow proper form inheritance. When having `HitForm < SongForm < Reform::Form` the `HitForm` class will contain `SongForm`'s properties in addition to its own fields.
* `::model` is now inherited properly.
* Allow instantiation of nested form with emtpy nested properties.

## 0.2.4

* Accessors for properties (e.g. `title` and `title=`) can now be overridden in the form *and* call `super`. This is extremely helpful if you wanna do "manual coercion" since the accessors are invoked in `#validate`. Thanks to @cj for requesting this.
* Inline forms now know their class name from the property that defines them. This is needed for I18N where `ActiveModel` queries the class name to compute translation keys. If you're not happy with it, use `::model`.

## 0.2.3

* `#form_for` now properly recognizes a nested form when declared using `:form` (instead of an inline form).
* Multiparameter dates as they're constructed from the Rails date helper are now processed automatically. As soon as an incoming attribute name is `property_name(1i)` or the like, it's compiled into a Date. That happens in `MultiParameterAttributes`. If a component (year/month/day) is missing, the date is considered `nil`.

## 0.2.2

* Fix a bug where `form.save do .. end` would call `model.save` even though a block was given. This no longer happens, if there's a block to `#save`, you have to manually save data (ActiveRecord environment, only).
* `#validate` doesn't blow up anymore when input data is missing for a nested property or collection.
* Allow `form: SongForm` to specify an explicit form class instead of using an inline form for nested properties.

## 0.2.1

* `ActiveRecord::i18n_scope` now returns `activerecord`.
* `Form#save` now calls save on the model in `ActiveRecord` context.
* `Form#model` is public now.
* Introduce `:empty` to have empty fields that are accessible for validation and processing, only.
* Introduce `:virtual` for read-only fields the are like `:empty` but initially read from the decorated model.
* Fix uniqueness validation with `Composition` form.
* Move `setup` and `save` logic into respective representer classes. This might break your code in case you overwrite private reform classes.


## 0.2.0

* Added nested property and collection for `has_one` and `has_many` relationships. . Note that this currently works only 1-level deep.
* Renamed `Reform::Form::DSL` to `Reform::Form::Composition` and deprecated `DSL`.
* `require 'reform'` now automatically requires Rails stuff in a Rails environment. Mainly, this is the FormBuilder compatibility layer that is injected into `Form`. If you don't want that, only require 'reform/form'.
* Composition now totally optional
* `Form.new` now accepts one argument, only: the model/composition. If you want to create your own representer, inject it by overriding `Form#mapper`. Note that this won't create property accessors for you.
* `Form::ActiveModel` no longer creates accessors to your represented models, e.g. having `property :title, on: :song` doesn't allow `form.song` anymore. This is because the actual model and the form's state might differ, so please use `form.title` directly.

## 0.1.3

* Altered `reform/rails` to conditionally load `ActiveRecord` code and created `reform/active_record`.

## 0.1.2

* `Form#to_model` is now delegated to model.
* Coercion with virtus works.

## 0.1.1

* Added `reform/rails` that requires everything you need (even in other frameworks :).
* Added `Form::ActiveRecord` that gives you `validates_uniqueness_with`. Note that this is strongly coupled to your database, thou.
* Merged a lot of cleanups from sweet @parndt <3.

## 0.1.0

* Oh yeah.
