# 2.0

* make Coercible optional (include it to activate)
* all options Uber:::Value with :method support



# NOTES
* use the same test setup everywhere (album -> songs -> composer)
* copy things in tests
* one test file per "feature": sync_test, sync_option_test.

* fields is a Twin and sorts out all the changed? stuff.
* virtual: don't read dont write
* empty dont read, but write
* read_only: read, don't write

* make SkipUnchanged default?


* `validates :title, :presence => true`
  with @model.title == "Little Green Car" and validate({}) the form is still valid (as we "have" a valid title). is that what we want?

* document Form#to_hash and Form#to_nested_hash (e.g. with OpenStruct composition to make it a very simple form)
* document getter: and representer_exec:

* Debug module that logs every step.
* no setters in Contract#setup

vererben in inline representern (module zum einmixen, attrs löschen)

# TODO: remove the concept of Errors#messages and just iterate over Errors.
# each form contains its local field errors in Errors
# form.messages should then go through them and compile a "summary" instead of adding them to the parents #errors in #validate.



in a perfect world, a UI form would send JSON as in the API. that's why the reform form creates the correct object graph first, then validates. creating the graph usually happens in the API representer code.


WHY DON'T PEOPLE USE THIS:
http://guides.rubyonrails.org/association_basics.html#the-has-many-association
4.2.2.2 :autosave

If you set the :autosave option to true, Rails will save any loaded members and destroy members that are marked for destruction whenever you save the parent object.