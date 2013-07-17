* `validates :title, :presence => true`
  with @model.title == "Little Green Car" and validate({}) the form is still valid (as we "have" a valid title). is that what we want?

* document Form#to_hash and Form#to_nested_hash (e.g. with OpenStruct composition to make it a very simple form)

* allow :as to rename nested forms