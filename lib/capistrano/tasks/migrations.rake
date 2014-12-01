namespace :deploy do
  namespace :migrations do
    desc <<-DESC
      Migrates database using the cakephp/migrations plugin.

      This is similar to running:

          bin/cake Migrations.migrations migrate

      For help:

          cap cakephp:help[migrations]

    DESC
    task :migrate do
      invoke "cakephp:migrations", "migrate"
    end

    desc <<-DESC
      Rollback database using the cakephp/migrations plugin

      This is similar to running:

          bin/cake Migrations.migrations rollback

      For help:

          cap cakephp:help[migrations]

    DESC
    task :rollback do
      invoke "cakephp:migrations", "rollback"
    end
  end

  task :migrations, :command_name do |t, args|
    # ask only runs if argument is not provided
    ask(:cmd, "list")
    command = args[:command_name] || fetch(:cmd)

    invoke "cakephp:cake", "Migrations.migrations", command, *args.extras
  end

end
