class RemoveAuthenticationTables < ActiveRecord::Migration[8.1]
  def change
    drop_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    drop_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.timestamps
      t.index :email_address, unique: true
    end
  end
end
