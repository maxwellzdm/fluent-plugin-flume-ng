# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "fluent-plugin-flume-ng"
  gem.homepage = "http://github.com/Deming Zhu/fluent-plugin-flume-ng"
  gem.license = "MIT"
  gem.summary = %Q{Fluentd Plugin For New Generation Flume}
  gem.description = %Q{Fluentd Plugin For New Generation Flume}
  gem.email = "deming.zhu@linecorp.com"
  gem.authors = ["DEMING ZHU"]
  gem.add_dependency "fluentd", "~> 0.10.16"
  gem.add_dependency "thrift", "~> 0.8.0"
  gem.files = Dir["lib/**/*"] +
       %w[VERSION  Rakefile fluent-plugin-flume-ng.gemspec]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "fluent-plugin-flume-ng #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
