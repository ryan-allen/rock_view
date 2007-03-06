task :default => [:test]

task :test do
  ruby 'test/test_runner.rb'
end