require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "capcake"
    gem.summary = ""
    gem.description = ""
    gem.email = "jad@wdtmedia.net"
    gem.homepage = ""
    gem.author = "Jad Bitar"
    gem.add_dependency "capistrano", ">= 2.5"
    gem.files = FileList["lib/**/*"].to_a
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end