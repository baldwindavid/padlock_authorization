class PadlockGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      # model
      m.template 'app/models/role.rb', 'app/models/role.rb'
      # migration
      m.migration_template 'db/migrate/migration.rb', 'db/migrate', :migration_file_name => "create_padlock_roles"
    end
  end
end
