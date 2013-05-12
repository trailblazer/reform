* `validates :title, :presence => true`
  with @model.title == "Little Green Car" and validate({}) the form is still valid (as we "have" a valid title). is that what we want?