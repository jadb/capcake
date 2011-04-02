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

And make sure you start capcake on the last line of that same file:

	capcake

You should then be able to proceed as you usually would. To familiarize yourself with the now modified list of tasks, you can get a full list with:

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

And finally, some CakePHP related settings (if omitted, Capcake will NOT handle deploying CakePHP):

	set :cake_branch, " "

You can change the default values for the following variables also:

	set :cake_branch, "1.2"
	set :cake_path, "/path/to"
	set :user, "your_username"
	set :branch, "tag"

## Alternative Easy Configuration

Simply replace your deploy.rb configuration file with the one provided in the template directory and change all variables on the lines that have comments with you values.

This configuration file is meant to work with [Multiple Stages Without Multistage Extension](https://github.com/capistrano/capistrano/wiki/2.x-Multiple-Stages-Without-Multistage-Extension) so every cap command will have to contain the stage you want to deploy to. For instance:

	$ cap staging deploy:setup
	$ cap staging deploy

## Deployment

The first time you are deploying, you need to run:

	# cap deploy:setup

That should create on your server the following directory structure:

	[deploy_to]
	[deploy_to]/releases
	[deploy_to]/shared
	[deploy_to]/shared/cakephp
	[deploy_to]/shared/system
	[deploy_to]/shared/tmp

Finally, deploy:

	# cap deploy

Which will change the directory structure to become:

	[deploy_to]
	[deploy_to]/current -> [deploy_to]/releases/20091013001122
	[deploy_to]/releases
	[deploy_to]/releases/20091013001122
	[deploy_to]/releases/20091013001122/system -> [deploy_to]/shared/system
	[deploy_to]/releases/20091013001122/tmp -> [deploy_to]/shared/tmp
	[deploy_to]/shared
	[deploy_to]/shared/cakephp
	[deploy_to]/shared/system
	[deploy_to]/shared/tmp

## Patches & Features

* Fork
* Mod, fix
* Test - this is important, so it's not unintentionally broken
* Commit - do not mess with license, todo, version, etc. (if you do change any, make them into commits of their own that I can ignore when I pull)
* Pull request - bonus point for topic branches

## Bugs & Feedback

http://github.com/jadb/capcake/issues
