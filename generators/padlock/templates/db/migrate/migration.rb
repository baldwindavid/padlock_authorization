class CreatePadlockRoles < ActiveRecord::Migration

  def self.up
    create_table :roles, :force => true do |t|
      t.string   :name, :authorizable_type
      t.integer  :authorizable_id
      t.timestamps
    end

    add_index :roles, ["name"], :name => "index_roles_on_name"

    create_table :roles_users, :id => false, :force => true do |t|
      t.integer  :role_id, :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :roles
    drop_table :roles_users
  end

end


