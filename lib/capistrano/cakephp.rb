require 'capistrano/composer'
require 'capistrano/file-permissions'
require 'capistrano/cakephp/cake'

namespace :load do
  task :defaults do
    load 'capistrano/cakephp/defaults.rb'
  end
end
