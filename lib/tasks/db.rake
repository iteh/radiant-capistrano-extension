namespace :db do
  desc "Dump the current database to a MySQL file"
  task :database_dump do
    load 'config/environment.rb'
    abcs = ActiveRecord::Base.configurations
    case abcs[RAILS_ENV]["adapter"]
    when 'mysql','mysql2'
      ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
      File.open("db/#{RAILS_ENV}_data.sql", "w+") do |f|
        if abcs[RAILS_ENV]["password"].blank?
          f << `mysqldump --skip-lock-tables -h #{abcs[RAILS_ENV]["host"]} -u #{abcs[RAILS_ENV]["username"]} #{abcs[RAILS_ENV]["database"]}`
        else
          f << `mysqldump --skip-lock-tables -h #{abcs[RAILS_ENV]["host"]} -u #{abcs[RAILS_ENV]["username"]} -p#{abcs[RAILS_ENV]["password"]} #{abcs[RAILS_ENV]["database"]}`
        end
      end
    else
      raise "Task not supported by '#{abcs[RAILS_ENV]['adapter']}'"
    end
  end

  desc "Refreshes your local development environment to the current production database"
  task :get_production_data_from_server do
    `cap remote_db_runner`
    `rake db:production_data_load --trace`
  end

  desc "Refreshes your remote production environment to the current development database"
  task :put_development_data_to_server do
    `rake RAILS_ENV=development db:database_dump --trace`
    `cap local_db_runner`
  end

  desc "Loads the production data downloaded into db/production_data.sql into your local development database"
  task :production_data_load do
    load 'config/environment.rb'
    abcs = ActiveRecord::Base.configurations
    case abcs[RAILS_ENV]["adapter"]
    when 'mysql','mysql2'
      ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
      if abcs[RAILS_ENV]["password"].blank?
        `mysql -h #{abcs[RAILS_ENV]["host"]} -u #{abcs[RAILS_ENV]["username"]} #{abcs[RAILS_ENV]["database"]} < db/production_data.sql`
      else
        `mysql -h #{abcs[RAILS_ENV]["host"]} -u #{abcs[RAILS_ENV]["username"]} -p#{abcs[RAILS_ENV]["password"]} #{abcs[RAILS_ENV]["database"]} < db/production_data.sql`
      end
    else
      raise "Task not supported by '#{abcs[RAILS_ENV]['adapter']}'"
    end
  end
  
  desc "Loads a specified sql to the environment db, defaults to db/development_data.sql"
  task :database_load do 
    require 'highline/import'
    say "ERROR: sql file #{ENV['SQL']} not found" and exit if (ENV['SQL'] && !File.exists?(ENV['SQL']))
    load 'config/environment.rb'
    abcs = ActiveRecord::Base.configurations  
    sql_file = ENV['SQL']||"db/development_data.sql"
    say "loading data from: #{sql_file}"
    case abcs[RAILS_ENV]["adapter"]
    when 'mysql','mysql2'
      ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
      if abcs[RAILS_ENV]["password"].blank?
        `mysql -h #{abcs[RAILS_ENV]["host"]} -u #{abcs[RAILS_ENV]["username"]} #{abcs[RAILS_ENV]["database"]} < #{sql_file}`
      else
        `mysql -h #{abcs[RAILS_ENV]["host"]} -u #{abcs[RAILS_ENV]["username"]} -p#{abcs[RAILS_ENV]["password"]} #{abcs[RAILS_ENV]["database"]} < #{sql_file}`
      end
    else
      raise "Task not supported by '#{abcs[RAILS_ENV]['adapter']}'"
    end
  end

end
