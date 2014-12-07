namespace :cakephp do
  desc <<-DESC
    Executes a cake command
  DESC
  task :cake, :command_name do |t, args|
    # ask only runs if argument is not provided
    ask(:cmd, "list")
    command = args[:command_name] || fetch(:cmd)

    on roles fetch(:cakephp_roles) do
      within release_path do
        execute "bin/cake", command, *args.extras, fetch(:cakephp_cake_options)
      end
    end
  end

end
