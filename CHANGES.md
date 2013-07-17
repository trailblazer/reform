h3. 0.2.0

* Composition now totally optional
* `Form.new` now accepts one argument, only: the model/composition. If you want to create your own representer, inject it by overriding `Form#mapper`. Note that this won't create property accessors for you.
* You can now nest forms. Note that this currently works only 1-level deep.
* `Form::ActiveModel` no longer creates accessors to your represented models, e.g. having `property :title, on: :song` doesn't allow `form.song` anymore. This is because the actual model and the form's state might differ, so please use `form.title` directly.

h3. 0.1.3

* Altered `reform/rails` to conditionally load `ActiveRecord` code and created `reform/active_record`.

h3. 0.1.2

* `Form#to_model` is now delegated to model.
* Coercion with virtus works.

h3. 0.1.1

* Added `reform/rails` that requires everything you need (even in other frameworks :).
* Added `Form::ActiveRecord` that gives you `validates_uniqueness_with`. Note that this is strongly coupled to your database, thou.
* Merged a lot of cleanups from sweet @parndt <3.

h3. 0.1.0

* Oh yeah.