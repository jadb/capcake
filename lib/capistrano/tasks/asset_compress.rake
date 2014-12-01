namespace :deploy do
  namespace :assets do
    desc <<-DESC
      Builds the assets using markstory/asset_compress plugin
    DESC
    task :build do
      invoke "cakephp:asset_compress", "build"
    end

    desc <<-DESC
      Clears the assets created using markstory/asset_compress plugin
    DESC
    task :clear do
      invoke "cakephp:asset_compress", "clear"
    end
  end

  task :asset_compress, :command_name do |t, args|
    # ask only runs if argument is not provided
    ask(:cmd, "list")
    command = args[:command_name] || fetch(:cmd)

    invoke "cakephp:cake", "AssetCompress.asset_compress", command, *args.extras
  end
end
