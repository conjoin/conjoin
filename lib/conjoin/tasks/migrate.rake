namespace :db do
  desc "create the database from config/database.yml from the current Sinatra env"
  task :create do
    ActiveRecordTasks.create()
  end

  desc "drops the data from config/database.yml from the current Sinatra env"
  task :drop do
    ActiveRecordTasks.drop()
  end

  desc "load the seed data from db/seeds.rb or run specific seed rake db:seed[file/path]"
  task :seed, :file do |t, args|
    ActiveRecordTasks.seed args[:file]
  end

  desc "create the database and load the schema"
  task :setup do
    ActiveRecordTasks.setup()
  end

  desc "create an ActiveRecord migration"
  task :create_migration do
    ActiveRecordTasks.create_migration(ENV["NAME"], ENV["VERSION"])
  end

  desc "migrate the database (use version with VERSION=n)"
  task :migrate do
    ActiveRecordTasks.migrate(ENV["VERSION"])
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  desc "roll back the migration (use steps with STEP=n)"
  task :rollback do
    ActiveRecordTasks.rollback(ENV["STEP"])
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  namespace :schema do
    desc "dump schema into file"
    task :dump do
      ActiveRecordTasks.dump_schema()
    end

    desc "load schema into database"
    task :load do
      ActiveRecordTasks.load_schema()
    end
  end

  namespace :test do
    task :purge do
      ActiveRecordTasks.with_config_environment 'test' do
        ActiveRecordTasks.purge()
      end
    end

    task :load => :purge do
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
      ActiveRecordTasks.with_config_environment 'test' do
        ActiveRecordTasks.load_schema()
      end
    end

    desc 'Prepare test database from development schema'
    task :prepare do
      Rake::Task["db:test:load"].invoke
    end
  end
end
