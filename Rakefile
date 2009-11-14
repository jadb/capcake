# Capcake Rakefile
#
# Author::    Jad Bitar (mailto:jadbitar@mac.com)
# Copyright:: Copyright (c) 2005-2009, WDT Media Corp (http://wdtmedia.net)
# License::   http://opensource.org/licenses/bsd-license.php The BSD License

require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "capcake"
    gem.summary = "Deploy CakePHP applications using Capistrano"
    gem.description = "Deploy CakePHP applications using Capistrano"
    gem.email = "jadbitar@mac.com"
    gem.homepage = "http://github.com/jadb/capcake"
    gem.author = "Jad Bitar"
    gem.add_dependency "capistrano", ">= 2.5"
    gem.files = FileList["lib/**/*"].to_a
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end