class AddApplicationIdToApiKey < ActiveRecord::Migration
  def change
    add_column :api_keys, :application_id, :integer
  end
end
