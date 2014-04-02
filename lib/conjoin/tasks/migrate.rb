require 'active_record'
require 'active_support/core_ext/string/strip'
require 'fileutils'
require 'highline/import'

module ActiveRecordTasks
  extend self

  def create
    silence_activerecord do
      ActiveRecord::Tasks::DatabaseTasks.create(config)
    end
  end

  def drop
    silence_activerecord do
      ActiveRecord::Tasks::DatabaseTasks.drop(config)
    end
  end

  def seed file = false
    if ENV['RACK_ENV'] == 'production'
      continue = ask("Running seeds could override data, proceed y/N? ", String)
    else
      continue = 'y'
    end

    if %w(yes y Y).include? continue
      silence_activerecord do
        load("db/seeds.rb")
        if not file
          Seeds.run
        else
          load("db/seeds/#{file}.rb")
        end
      end
    else
      say 'Aborting!'
    end
  end

  def setup
    silence_activerecord do
      create()
      load_schema()
      seed()
    end
  end

  def create_migration(migration_name, version = nil)
    raise "No NAME specified. Example usage: `rake db:create_migration NAME=create_users`" if migration_name.nil?

    migration_number = version || Time.now.utc.strftime("%Y%m%d%H%M%S")
    migration_file = File.join(migrations_dir, "#{migration_number}_#{migration_name}.rb")
    migration_class = migration_name.split("_").map(&:capitalize).join

    FileUtils.mkdir_p(migrations_dir)
    File.open(migration_file, 'w') do |file|
      file.write <<-MIGRATION.strip_heredoc
        class #{migration_class} < ActiveRecord::Migration
          def change
          end
        end
      MIGRATION
    end
  end

  def migrate(version = nil)
    silence_activerecord do
      migration_version = version ? version.to_i : version
      ActiveRecord::Migrator.migrate(migrations_dir, migration_version)
    end
  end

  def rollback(step = nil)
    silence_activerecord do
      migration_step = step ? step.to_i : 1
      ActiveRecord::Migrator.rollback(migrations_dir, migration_step)
    end
  end

  def dump_schema(file_name = 'db/schema.rb')
    silence_activerecord do
      ActiveRecord::Migration.suppress_messages do
        # Create file
        out = File.new(file_name, 'w')

        # Load schema
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, out)

        out.close
      end
    end
  end

  def purge
    if config
      ActiveRecord::Tasks::DatabaseTasks.purge(config)
    else
      raise ActiveRecord::ConnectionNotEstablished
    end
  end

  def load_schema(file_name = 'db/schema.rb')
    load(file_name)
  end

  private

  def config
    db = URI.parse ENV['DATABASE_URL']

    {
      adapter: db.scheme == 'postgres' ? 'postgresql' : db.scheme,
      encoding: 'utf8',
      reconnect: true,
      database: db.path[1..-1],
      host: db.host,
      port: db.port,
      pool: ENV['DATABASE_POOL'] || 5,
      username: db.user,
      password: db.password
    }
  end

  def connect_to_active_record
    ActiveRecord::Base.establish_connection config
  end

  def migrations_dir
    ActiveRecord::Migrator.migrations_path
  end

  def silence_activerecord(&block)
    connect_to_active_record

    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    yield if block_given?
    ActiveRecord::Base.logger = old_logger
  end
end
