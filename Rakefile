require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'yaml'

namespace :db do

  desc 'Migrate the database'
  task :migrate do
    connection_details = YAML::load(File.open('config/database.yml'))
    ActiveRecord::Base.establish_connection(connection_details)
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.migration_context.migrate
    end
    Rake::Task["db:schema"].invoke
  end

  desc 'Rollback the database'
  task :rollback do
    connection_details = YAML::load(File.open('config/database.yml'))
    ActiveRecord::Base.establish_connection(connection_details)
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.migration_context.rollback
    end
    Rake::Task["db:schema"].invoke
  end

  desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
  task :schema do
    connection_details = YAML::load(File.open('config/database.yml'))
    ActiveRecord::Base.establish_connection(connection_details)
    require 'active_record/schema_dumper'
    filename = "db/schema.rb"
    File.open(filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end

  desc 'Create the database'
  task :create do
    connection_details = YAML::load(File.open('config/database.yml'))
#    admin_connection = connection_details.merge({'database'=> 'postgres',
#                                                'schema_search_path'=> 'public'})
    ActiveRecord::Base.establish_connection(connection_details)
    ActiveRecord::Base.connection.create_database(connection_details.fetch('database'))
  end

  desc 'Drop the database'
  task :drop do
    connection_details = YAML::load(File.open('config/database.yml'))
#    admin_connection = connection_details.merge({'database'=> 'postgres',
#                                                'schema_search_path'=> 'public'})
    ActiveRecord::Base.establish_connection(connection_details)
    ActiveRecord::Base.connection.drop_database(connection_details.fetch('database'))
  end
end
