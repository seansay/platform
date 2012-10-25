class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.integer :user_id
      t.string :request_token
      t.string :secret_token
      t.boolean :active

      t.timestamps
    end
  end
end
