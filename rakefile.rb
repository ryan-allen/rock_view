task :default => [:test]

task :test do
  require 'test/template_test'
  require 'test/dsl_test'
  require 'test/loader_test'
  require 'test/base_test'
  require 'test/spec_test'
end