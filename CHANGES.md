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