# Capistrano::cakephp

Deploy CakePHP applications with Capistrano v3.*

IMPORTANT: Tested with CakePHP 3 thus far, but should work for CakePHP 2 that uses composer.

## Requirements

The remote server(s) require the `acl` package:

```
$ sudo apt-get install acl
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano', '~> 3.0.0'
gem 'capcake', '~> 3.0.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capcake

At this point, you can install capistrano:

    $ cap install

This will create the required files in your `ROOT/config` directory

At any time, for help:

    $ cap -T

### Suggestions

Add `.capistrano` to your `.gitignore`:

```
echo .capistrano/* >> .gitignore
```

## Usage

Require the module in your `Capfile`:

```ruby
require 'capistrano/cakephp'
```

Some extras:

```ruby
require 'capistrano/cakephp/assets'
require 'capistrano/cakephp/migrations'
```

### Configuration

The gem makes the following configuration variables available (shown with defaults)

```ruby
set :cakephp_roles, :all
set :cakephp_flags, ''
set :cakephp_user, 'www-data'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
