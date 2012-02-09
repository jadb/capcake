# Capcake capistrano's recipe
#
# Author::    Jad Bitar (mailto:jadbitar@mac.com)
# Copyright:: Copyright (c) 2005-2009, WDT Media Corp (http://wdtmedia.net)
# License::   http://opensource.org/licenses/bsd-license.php The BSD License

Capistrano::Configuration.instance(:must_exist).load do

  require 'capistrano/recipes/deploy/scm'
  require 'capistrano/recipes/deploy/strategy'

  # =========================================================================
  # These variables may be set in the client capfile if their default values
  # are not sufficient.
  # =========================================================================

  set :application,   ""
  set :branch,        "master"
  set :deploy_to,     ""
  set :keep_releases, 5
  set :repository,    ""
  set :use_sudo,      false
  set :user,          "deployer"

  # =========================================================================
  # These variables should NOT be changed unless you are very confident in
  # what you are doing. Make sure you understand all the implications of your
  # changes if you do decide to muck with these!
  # =========================================================================

  set :cake2,                 true
  set :scm,                   :git
  set :git_enable_submodules, 1
  set :deploy_via,            :checkout

  set :git_flag_quiet,        ""

  _cset(:cake_branch)         { "" }
  _cset(:cake_repo)	          { "git://github.com/cakephp/cakephp.git" }
  _cset :tmp_children,        %w(cache logs sessions tests)
  _cset :cache_children,      %w(models persistent views)
  _cset :logs_files,          %w(debug error)

  def capcake()
    set :deploy_to,           "/var/www/#{application}" if (deploy_to.empty?)
    set(:current_path)        { File.join(deploy_to, current_dir) }
    if cake2
      set :shared_children,       %w(Config System tmp)
      set :database_partial_path, "Config/database.php"
    else
      set :shared_children,       %w(config system tmp)
      set :database_partial_path, "config/database.php"
    end
    set(:database_path)       { File.join(shared_path, database_partial_path) }
    set(:shared_path)         { File.join(deploy_to, shared_dir) }
    _cset(:cake_path)         { shared_path }
    _cset(:tmp_path)          { File.join(shared_path, "tmp") }
    _cset(:cache_path)        { File.join(tmp_path, "cache") }
    _cset(:logs_path)         { File.join(tmp_path, "logs") }

  end

  def defaults(val, default)
    val = default if (val.empty?)
    val
  end

  def remote_file_exists?(full_path)
    'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  end

  # =========================================================================
  # These are the tasks that are available to help with deploying web apps,
  # and specifically, Rails applications. You can have cap give you a summary
  # of them with `cap -T'.
  # =========================================================================

  namespace :deploy do
    desc <<-DESC
      Deploys your project. This calls `update`. Note that \
      this will generally only work for applications that have already been deployed \
      once. For a "cold" deploy, you'll want to take a look at the `deploy:cold` \
      task, which handles the cold start specifically.
    DESC
    task :default do
      update
    end
    desc <<-DESC
      Prepares one or more servers for deployment. Before you can use any \
      of the Capistrano deployment tasks with your project, you will need to \
      make sure all of your servers have been prepared with `cap deploy:setup`. When \
      you add a new server to your cluster, you can easily run the setup task \
      on just that server by specifying the HOSTS environment variable:

        $ cap HOSTS=new.server.com deploy:setup

      It is safe to run this task on servers that have already been set up; it \
      will not destroy any deployed revisions or data.
    DESC
    task :setup, :except => { :no_release => true } do
      dirs = [deploy_to, releases_path, shared_path]
      dirs += shared_children.map { |d| File.join(shared_path, d) }
      tmp_dirs = tmp_children.map { |d| File.join(tmp_path, d) }
      tmp_dirs += cache_children.map { |d| File.join(cache_path, d) }
      run "#{try_sudo} mkdir -p #{(dirs + tmp_dirs).join(' ')} && #{try_sudo} chmod -R 777 #{tmp_path}" if (!user.empty?)
      set :git_flag_quiet, "-q "
      cake.setup if (!cake_branch.empty?)
      cake.database.config if (!remote_file_exists?(database_path))
    end

    desc <<-DESC
      Copies your project and updates the symlink. It does this in a \
      transaction, so that if either `update_code` or `symlink` fail, all \
      changes made to the remote servers will be rolled back, leaving your \
      system in the same state it was in before `update` was invoked. Usually, \
      you will want to call `deploy` instead of `update`, but `update` can be \
      handy if you want to deploy, but not immediately restart your application.
    DESC
    task :update do
      transaction do
        update_code
        symlink
	cake.cache.clear
      end
    end

    desc <<-DESC
      Copies your project to the remote servers. This is the first stage \
      of any deployment; moving your updated code and assets to the deployment \
      servers. You will rarely call this task directly, however; instead, you \
      should call the `deploy` task (to do a complete deploy) or the `update` \
      task (if you want to perform the `restart` task separately).

      You will need to make sure you set the :scm variable to the source \
      control software you are using (it defaults to :subversion), and the \
      :deploy_via variable to the strategy you want to use to deploy (it \
      defaults to :checkout).
    DESC
    task :update_code, :except => { :no_release => true } do
      on_rollback { run "rm -rf #{release_path}; true" }
      strategy.deploy!
      finalize_update
    end

    desc <<-DESC
      [internal] This task will make the release group-writable (if the :group_writable \
      variable is set to true, which is the default). 
    DESC
    task :finalize_update, :except => { :no_release => true } do
      run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    end

    desc <<-DESC
      Updates the symlinks to the most recently deployed version. Capistrano works \
      by putting each new release of your application in its own directory. When \
      you deploy a new version, this task's job is to update the `current`, \
      `current/tmp`, `current/webroot/system` symlinks to point at the new version. \
      
      You will rarely need to call this task directly; instead, use the `deploy` \
      task (which performs a complete deploy, including `restart`) or the 'update` \
      task (which does everything except `restart`).
    DESC
    task :symlink, :except => { :no_release => true } do
      on_rollback do
        if previous_release
          run "rm -f #{current_path}; ln -s #{previous_release} #{current_path}; true"
        else
          logger.important "no previous release to rollback to, rollback of symlink skipped"
        end
      end
      run "rm -rf #{latest_release}/tmp" if (!remote_file_exists?("#{latest_release}/tmp/empty"))
      run "ln -s #{shared_path}/system #{latest_release}/webroot/system && ln -s #{shared_path}/tmp #{latest_release}/tmp";
      run "rm -f #{current_path} && ln -s #{latest_release} #{current_path}"
      cake.database.symlink if (remote_file_exists?(database_path))
    end

    desc <<-DESC
      Copy files to the currently deployed version. This is useful for updating \
      files piecemeal, such as when you need to quickly deploy only a single \
      file. Some files, such as updated templates, images, or stylesheets, \
      might not require a full deploy, and especially in emergency situations \
      it can be handy to just push the updates to production, quickly.

      To use this task, specify the files and directories you want to copy as a \
      comma-delimited list in the FILES environment variable. All directories \
      will be processed recursively, with all files being pushed to the \
      deployment servers.

        $ cap deploy:upload FILES=templates,controller.rb

      Dir globs are also supported:

        $ cap deploy:upload FILES='config/apache/*.conf'
    DESC
    task :upload, :except => { :no_release => true } do
      files = (ENV["FILES"] || "").split(",").map { |f| Dir[f.strip] }.flatten
      abort "Please specify at least one file or directory to update (via the FILES environment variable)" if files.empty?

      files.each { |file| top.upload(file, File.join(current_path, file)) }
    end

    namespace :rollback do
      desc <<-DESC
        [internal] Points the current symlink at the previous revision.
        This is called by the rollback sequence, and should rarely (if
        ever) need to be called directly.
      DESC
      task :revision, :except => { :no_release => true } do
        if previous_release
          run "rm #{current_path}; ln -s #{previous_release} #{current_path};"
        else
          abort "could not rollback the code because there is no prior release"
        end
      end

      desc <<-DESC
        [internal] Removes the most recently deployed release.
        This is called by the rollback sequence, and should rarely
        (if ever) need to be called directly.
      DESC
      task :cleanup, :except => { :no_release => true } do
        run "if [ `readlink #{current_path}` != #{current_release} ]; then rm -rf #{current_release}; fi"
      end

      desc <<-DESC
        Rolls back to the previously deployed version. The `current` symlink will \
        be updated to point at the previously deployed version, and then the \
        current release will be removed from the servers.
      DESC
      task :code, :except => { :no_release => true } do
        revision
        cleanup
      end

      desc <<-DESC
        Rolls back to a previous version and restarts. This is handy if you ever \
        discover that you've deployed a lemon; `cap rollback` and you're right \
        back where you were, on the previously deployed version.
      DESC
      task :default do
        revision
        cleanup
      end
    end

    desc <<-DESC
      Clean up old releases. By default, the last 5 releases are kept on each \
      server (though you can change this with the keep_releases variable). All \
      other deployed revisions are removed from the servers. By default, this \
      will use sudo to clean up the old releases, but if sudo is not available \
      for your environment, set the :use_sudo variable to false instead.
    DESC
    task :cleanup, :except => { :no_release => true } do
      count = fetch(:keep_releases, 5).to_i
      if count >= releases.length
        logger.important "no old releases to clean up"
      else
        logger.info "keeping #{count} of #{releases.length} deployed releases"

        directories = (releases - releases.last(count)).map { |release|
          File.join(releases_path, release) }.join(" ")

        try_sudo "rm -rf #{directories}"
      end
    end

    desc <<-DESC
      Test deployment dependencies. Checks things like directory permissions, \
      necessary utilities, and so forth, reporting on the things that appear to \
      be incorrect or missing. This is good for making sure a deploy has a \
      chance of working before you actually run `cap deploy`.

      You can define your own dependencies, as well, using the `depend' method:

        depend :remote, :gem, "tzinfo", ">=0.3.3"
        depend :local, :command, "svn"
        depend :remote, :directory, "/u/depot/files"
    DESC
    task :check, :except => { :no_release => true } do
      dependencies = strategy.check!

      other = fetch(:dependencies, {})
      other.each do |location, types|
        types.each do |type, calls|
          if type == :gem
            dependencies.send(location).command(fetch(:gem_command, "gem")).or("`gem' command could not be found. Try setting :gem_command")
          end

          calls.each do |args|
            dependencies.send(location).send(type, *args)
          end
        end
      end

      if dependencies.pass?
        puts "You appear to have all necessary dependencies installed"
      else
        puts "The following dependencies failed. Please check them and try again:"
        dependencies.reject { |d| d.pass? }.each do |d|
          puts "--> #{d.message}"
        end
        abort
      end
    end

    desc <<-DESC
      Deploys and starts a `cold` application. This is useful if you have never \
      deployed your application before. It currently runs `deploy:setup` followed \
      by `deploy:update`. \
      (This is still an experimental feature, and is subject to change without \
      notice!)
    DESC
    task :cold do
      setup
      update
    end

    namespace :pending do
      desc <<-DESC
        Displays the `diff` since your last deploy. This is useful if you want \
        to examine what changes are about to be deployed. Note that this might \
        not be supported on all SCM's.
      DESC
      task :diff, :except => { :no_release => true } do
        system(source.local.diff(current_revision))
      end

      desc <<-DESC
        Displays the commits since your last deploy. This is good for a summary \
        of the changes that have occurred since the last deploy. Note that this \
        might not be supported on all SCM's.
      DESC
      task :default, :except => { :no_release => true } do
        from = source.next_revision(current_revision)
        system(source.local.log(from))
      end
    end

    namespace :web do
      desc <<-DESC
        Present a maintenance page to visitors. Disables your application's web \
        interface by writing a "maintenance.html" file to each web server. The \
        servers must be configured to detect the presence of this file, and if \
        it is present, always display it instead of performing the request.

        By default, the maintenance page will just say the site is down for \
        "maintenance", and will be back "shortly", but you can customize the \
        page by specifying the REASON and UNTIL environment variables:

          $ cap deploy:web:disable \\
                REASON="hardware upgrade" \\
                UNTIL="12pm Central Time"

        Further customization will require that you write your own task.
      DESC
      task :disable, :roles => :web, :except => { :no_release => true } do
        require 'erb'
        on_rollback { run "rm #{shared_path}/system/maintenance.html" }

        warn <<-EOHTACCESS

          # Please add something like this to your site's htaccess to redirect users to the maintenance page.
          # More Info: http://www.shiftcommathree.com/articles/make-your-rails-maintenance-page-respond-with-a-503

          ErrorDocument 503 /system/maintenance.html
          RewriteEngine On
          RewriteCond %{REQUEST_URI} !\.(css|gif|jpg|png)$
          RewriteCond %{DOCUMENT_ROOT}/system/maintenance.html -f
          RewriteCond %{SCRIPT_FILENAME} !maintenance.html
          RewriteRule ^.*$  -  [redirect=503,last]
        EOHTACCESS

        reason = ENV['REASON']
        deadline = ENV['UNTIL']

        template = File.read(File.join(File.dirname(__FILE__), "templates", "maintenance.rhtml"))
        result = ERB.new(template).result(binding)

        put(result, "#{shared_path}/system/maintenance.html", :mode => 0644, :via => :scp)
      end

      desc <<-DESC
        Makes the application web-accessible again. Removes the \
        "maintenance.html" page generated by deploy:web:disable, which (if your \
        web servers are configured correctly) will make your application \
        web-accessible again.
      DESC
      task :enable, :roles => :web, :except => { :no_release => true } do
        run "rm #{shared_path}/system/maintenance.html"
      end
    end

    desc <<-DESC
      Quick server(s) reset. For now, it deletes all files/folders in :deploy_to \
      (This is still an experimental feature, and is subject to change without \
      notice!) \

      Used only when first testing setup deploy recipes and want to quickly \
      reset servers.
    DESC
    task :destroy do
      set(:confirm) do
        Capistrano::CLI.ui.ask "This will delete your project on all servers. Are you sure you wish to continue? [Y/n]"
      end
      run "#{try_sudo} rm -rf #{deploy_to}/*" if (confirm == "Y")
    end

  end

  namespace :cake do

    desc <<-DESC
      Prepares server for deployment of a CakePHP application. \

      By default, it will create a shallow clone of the CakePHP repository \
      inside #{shared_path}/cakephp and run `deploy:cake:update`.

      For more info about shallow clones: \
      http://www.kernel.org/pub/software/scm/git/docs/git-clone.html \

      Further customization will require that you write your own task.
    DESC
    desc "Prepares server for deployment of a CakePHP application"
    task :setup do
      run "cd #{cake_path} && git clone --depth 1 #{cake_repo} cakephp"
      set :git_flag_quiet, "-q "
      update
    end
    desc <<-DESC
      Force CakePHP installation to checkout a new branch/tag. \

      By default, it will checkout the :cake_branch you set in \
      deploy.rb, but you can change that on runtime by specifying \
      the BRANCH environment variable:

        $ cap deploy:cake:update \\
              BRANCH="1.3.0-alpha"

      Further customization will require that you write your own task.
    DESC
    task :update do
      set :cake_branch, ENV['BRANCH'] if ENV.has_key?('BRANCH')
      stream "cd #{cake_path}/cakephp && git checkout #{git_flag_quiet}#{cake_branch}"
      if cake2
        run "#{try_sudo} ln -s #{shared_path}/cakephp/lib #{deploy_to}/#{version_dir}/lib"
      else
        run "#{try_sudo} ln -s #{shared_path}/cakephp/cake #{deploy_to}/#{version_dir}/cake"
      end
      run "#{try_sudo} mkdir -m 777 -p #{shared_path}/cakephp/media/transfer/img"
      run "#{try_sudo} mkdir -m 777 -p #{shared_path}/cakephp/media/static/img"
      run "#{try_sudo} mkdir -m 777 -p #{shared_path}/cakephp/media/filter"
      run "#{try_sudo} ln -s #{shared_path}/cakephp/media #{deploy_to}/#{version_dir}/media"
      run "#{try_sudo} ln -s #{shared_path}/cakephp/plugins #{deploy_to}/#{version_dir}/plugins"
      run "#{try_sudo} ln -s #{shared_path}/cakephp/vendors #{deploy_to}/#{version_dir}/vendors"
    end

    namespace :cache do
      desc <<-DESC
        Clears CakePHP's APP/tmp/cache and its sub-directories.

        Recursively finds all files in :cache_path and runs `rm -f` on each. If a file \
        is renamed/removed after it was found but before it removes it, no error \
        will prompt (-ignore_readdir_race). If symlinks are found, they will not be followed

        You will rarely need to call this task directly; instead, use the `deploy` \
        task (which performs a complete deploy, including `cake:cache:clear`)
      DESC
      task :clear, :roles => :web, :except => { :no_release => true } do
        run "#{try_sudo} find -P #{cache_path} -ignore_readdir_race -type f -name '*' -exec rm -f {} \\;"
      end
    end

    namespace :database do
      desc <<-DESC
        Generates CakePHP database configuration file in #{shared_path}/config \
        and symlinks #{current_path}/config/database.php to it
      DESC
      task :config, :roles => :web, :except => { :no_release => true } do
        require 'erb'
        on_rollback { run "rm #{database_path}" }
        puts "Database configuration"
        if cake2
          set :db_driver_or_datasource, 'datasource'
          _cset :db_driver_or_datasource_value, defaults(Capistrano::CLI.ui.ask("datasource [Database/Mysql]:"), 'Database/Mysql')
        else
          set :db_driver_or_datasource, 'driver'
          _cset :db_driver_or_datasource_value, defaults(Capistrano::CLI.ui.ask("driver [mysql]:"), 'mysql')
        end
        _cset :db_host, defaults(Capistrano::CLI.ui.ask("hostname [localhost]:"), 'localhost')
        _cset :db_login, defaults(Capistrano::CLI.ui.ask("username [#{user}]:"), user)
        _cset :db_password, Capistrano::CLI.password_prompt("password:")
        _cset :db_name, defaults(Capistrano::CLI.ui.ask("db name [#{application}]:"), application)
        _cset :db_prefix, Capistrano::CLI.ui.ask("prefix:")
        _cset :db_persistent, defaults(Capistrano::CLI.ui.ask("persistent [false]:"), 'false')
        _cset :db_encoding, defaults(Capistrano::CLI.ui.ask("encoding [utf8]:"), 'utf8')

        template = File.read(File.join(File.dirname(__FILE__), "templates", "database.rphp"))
        result = ERB.new(template).result(binding)

        put(result, "#{database_path}", :mode => 0644, :via => :scp)
        after("deploy:symlink", "cake:database:symlink")
      end
      desc <<-DESC
        Creates MySQL database, database user and grants permissions on DB servers
      DESC
      task :create, :roles => :db, :except => { :no_release => true } do
        require 'erb'

        _cset :mysql_admin_user, defaults(Capistrano::CLI.ui.ask("username [root]:"), 'root')
        _cset :mysql_admin_password, Capistrano::CLI.password_prompt("password:")

        _cset :mysql_grant_priv_type, defaults(Capistrano::CLI.ui.ask("Grant privilege types:"), 'ALL')
        _cset :mysql_grant_locations, defaults(Capistrano::CLI.ui.ask("Grant locations:"), ["localhost"])

        _cset :db_login, defaults(Capistrano::CLI.ui.ask("username [#{user}]:"), user)
        _cset :db_password, Capistrano::CLI.password_prompt("password:")
        _cset :db_name, defaults(Capistrano::CLI.ui.ask("db name [#{application}]:"), application)
        _cset :db_encoding, defaults(Capistrano::CLI.ui.ask("encoding [utf8]:"), 'utf8')

        set :tmp_filename, File.join(shared_path, "config/create_db_#{db_name}.sql") 

        template = File.read(File.join(File.dirname(__FILE__), "templates", "create_database.rsql"))
        result = ERB.new(template).result(binding)

        put(result, "#{tmp_filename}", :mode => 0644, :via => :scp)

        run "mysql -u #{mysql_admin_user} -p#{mysql_admin_password} < #{tmp_filename}"
        run "#{try_sudo} rm #{tmp_filename}"
      end
      desc <<-DESC
        Creates database tables on primary DB servers
      DESC
      task :schema, :roles => :db, :primary => true, :except => { :no_release => true } do
        # ...
      end
      desc <<-DESC
        Creates required CakePHP's APP/config/database.php as a symlink to \
        #{deploy_to}/shared/config/database.php
      DESC
      task :symlink, :roles => :web, :except => { :no_release => true } do
        run "#{try_sudo} rm -f #{current_path}/#{database_partial_path} && #{try_sudo} ln -s #{database_path} #{current_path}/#{database_partial_path}"
      end
    end

    namespace :logs do
      desc <<-DESC
        Clears CakePHP's APP/tmp/logs and its sub-directories

        Recursively finds all files in :logs_path and runs `rm -f` on each. If a file \
        is renamed/removed after it was found but before it removes it, no error \
        will prompt (-ignore_readdir_race). If symlinks are found, they will not be followed

      DESC
      task :clear, :roles => :web, :except => { :no_release => true } do
        run "#{try_sudo} find -P #{logs_path} -ignore_readdir_race -type f -name '*' -exec rm -f {} \\;"
      end
      desc <<-DESC
        Streams the result of `tail -f` on all :logs_files \

        By default, the files are `debug` and `error`. You can add your own \
        in config/deploy.rb

          set :logs_files %w(debug error my_log_file)

      DESC
      task :tail, :roles => :web, :except => { :no_release => true } do
        files = logs_files.map { |d| File.join(logs_path, d) }
        stream "#{try_sudo} tail -f #{files.join(' ')}"
      end
    end

  end

end # Capistrano::Configuration.instance(:must_exist).load do
