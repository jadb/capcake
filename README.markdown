# capcake

Looking to deploy a CakePHP application you've built? Capcake extends Capistrano, removing the `rails-ism`, replacing them by more `cake-ish` ones.

## Installation

    # gem install capcake -s http://gemcutter.org

## Usage

Prepend your config/deploy.rb with the following lines:
    require 'rubygems'
    require 'capcake'

You should then be able to proceed as you would usually. To familiarise yourself with the now modified list of tasks, you can get a full list with:

    $ cap -T

## Bugs & Feedback

http://github.com/jadb