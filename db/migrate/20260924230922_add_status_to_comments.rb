class AddStatusToComments < ActiveRecord::Migration[8.1]
  def change
    # Enforces a default status of 'pending' for all new comments
    add_column :comments, :status, :string, default: "pending", null: false
    add_index :comments, :status
  end
end