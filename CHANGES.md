## 0.2.2

* Fix a bug where `form.save do .. end` would call `model.save` even though a block was given. This no longer happens, if there's a block to `#save`, you have to manually save data (ActiveRecord environment, only).

h3. 0.2.1

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