task :default => [:test]

task :test do
  require 'test/template_test.rb'
  require 'test/dsl_test.rb'
  require 'test/loader_test.rb'
end