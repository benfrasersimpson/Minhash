require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
    t.test_files = FileList['test/*_test.rb']
    t.libs << 'lib'
    t.verbose = true
end
