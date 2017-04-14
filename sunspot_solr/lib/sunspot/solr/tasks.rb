namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task start: :environment do
      case RUBY_PLATFORM
      when /w(in)?32$/, /java$/
        abort("This command is not supported on #{RUBY_PLATFORM}. " +
              "Use rake sunspot:solr:run to run Solr in the foreground.")
      end
      # TODO don't hardcode port if a yml file is present
      sh 'bundle exec rake sunspot-solr start -p 8982'
      puts 'Successfully started Solr ...'
    end

    desc 'Run the Solr instance in the foreground'
    task run: :environment do
    end

    desc 'Stop the Solr instance'
    task stop: :environment do
      sh "ps -ef | grep solr | grep -v grep | awk '{ print $2 }' | xargs kill "
      puts 'Successfully stopped Solr ...'
    end

    desc 'Restart the Solr instance'
    task restart: :environment do
      Rake::Task['sunspot:solr:stop'].invoke if File.exist?(server.pid_path)
      Rake::Task['sunspot:solr:start'].invoke
    end

    # for backwards compatibility
    task :reindex, [:batch_size, :models, :silence] => :"sunspot:reindex"
  end
end
