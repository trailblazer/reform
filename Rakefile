require "bundler/gem_tasks"
require 'rake/testtask'

task :default => [:test]
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/*_test.rb']

#   test.test_files = ["test/changed_test.rb",
#   "test/coercion_test.rb",
#   "test/feature_test.rb",

#   "test/contract_test.rb",

#   "test/populate_test.rb", "test/prepopulator_test.rb",

#   "test/readable_test.rb","test/setup_test.rb","test/skip_if_test.rb",

#   "test/validate_test.rb", "test/save_test.rb",

#   "test/writeable_test.rb","test/virtual_test.rb",

#   "test/form_builder_test.rb", "test/active_model_test.rb",

#   "test/readonly_test.rb",
#   "test/inherit_test.rb",
#   "test/uniqueness_test.rb",
#   "test/from_test.rb",
#   "test/composition_test.rb",
#   "test/form_option_test.rb",
#   "test/form_test.rb",
#   "test/deserialize_test.rb",
#   "test/module_test.rb"
# ]



  test.verbose = true
end

Rake::TestTask.new(:test_rails) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/rails/*_test.rb']
  test.verbose = true
end