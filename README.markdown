# capcake

Looking to deploy a [CakePHP](http://cakephp.org) application you've built? Capcake extends [Capistrano](http://capify.org), removing the *rails-ism*, replacing them by more *cake-ish* ones.

## Installation

If you don't have Capistrano and/or Capcake already installed (basically, just the 1st time):

   # gem install capistrano
   # gem install capcake -s http://gemcutter.org

For every application you'll want to deploy:

   # cd /path/to/app && capify .

This will create the following files in your project (don't forget to commit them!):

   capfile
   config/deploy.rb
   
Prepend your config/deploy.rb with the following lines:

    require 'rubygems'
    require 'capcake'

You should then be able to proceed as you would usually. To familiarize yourself with the now modified list of tasks, you can get a full list with:

    $ cap -T

## Configuration

Before continuing, some changes to config/deploy.rb are necessary. First, your project's name:

   set :application, "your_app_name"

Next, setting up the Git repository (make sure it's accessible by both your local machine and server your are deploying to):

   set :repository, "git@domain.com:path/to/repo"

Now, to deploy from Git, and by following [GitHub's suggestion](http://github.com/guides/deploying-with-capistrano) (they must know what they are talking about), add a user (defaults to *deployer* by capcake's recipe) to your server(s) just for deployments. In this example, I will be using SSH keys instead of getting a Git password prompt. Local user's SSH key must be added to *deployer*'s ~/.ssh/authorized_keys for this to work as described. 

   ssh_options[:forward_agent] = true

We need to tell it where to deploy, using what methods:

   server "www.domain.tld", :app, :db, :primary => true

And finally, some CakePHP related settings:

   set :cake_branch, "1.3.0-alpha"

For this to work, *deployer*'s SSH keys must be added to the [Chaw](http://thechaw.com/users/account).

You can change the default values for the following variables also:

   set :cake_branch, "1.2"
   set :cake_path, "/path/to"
   set :user, "your_username"
   set :branch, "tag"

## Deployment

The first time you are deploying, you need to run:

   # cap deploy:setup

That should create on your server the following directory structure:

   [deploy_to]
   [deploy_to]/releases
   [deploy_to]/releases/20091013001122
   [deploy_to]/releases/20091013001122/tmp -> [deploy_to]/shared/tmp
   [deploy_to]/releases/...
   [deploy_to]/shared
   [deploy_to]/shared/cakephp
   [deploy_to]/shared/tmp
   [deploy_to]/shared/...
   [deploy_to]/current -> [deploy_to]/releases/20091013001122

Finally, deploy:

   # cap deploy

To get the most up-to-date list of available tasks, run:

# cap -T

## Bugs & Feedback

http://github.com/jadb