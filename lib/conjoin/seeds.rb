module Conjoin
  module Seeds
    class << self
      def root
        File.expand_path(File.dirname(__FILE__))
      end

      def run
        Dir["#{root}/seeds/**/*.rb"].each  { |rb| require rb  }
      end

      def load_sql_dump_for dump
        connection = ActiveRecord::Base.connection

        connection.execute("TRUNCATE #{dump};")

        # - IMPORTANT: SEED DATA ONLY
        # - DO NOT EXPORT TABLE STRUCTURES
        # - DO NOT EXPORT DATA FROM `schema_migrations`
        sql = File.read("db/dumps/#{dump}.sql")
        statements = sql.split(/;$/)
        statements.pop  # the last empty statement

        ActiveRecord::Base.transaction do
          statements.each do |statement|
            connection.execute(statement)
          end
        end
      end
    end
  end
end
