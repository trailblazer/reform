* `validates :title, :presence => true`
  with @model.title == "Little Green Car" and validate({}) the form is still valid (as we "have" a valid title). is that what we want?

* document Form#to_hash and Form#to_nested_hash (e.g. with OpenStruct composition to make it a very simple form)
* document getter: and representer_exec:

* allow :as to rename nested forms

vererben in inline representern (module zum einmixen, attrs löschen)

# TODO: remove the concept of Errors#messages and just iterate over Errors.
# each form contains its local field errors in Errors
# form.messages should then go through them and compile a "summary" instead of adding them to the parents #errors in #validate.


in a perfect world, a UI form would send JSON as in the API. that's why the reform form creates the correct object graph first, then validates. creating the graph usually happens in the API representer code.