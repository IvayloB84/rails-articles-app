class FixCommentStatusDefaults < ActiveRecord::Migration[8.1]
  def change
    # 1. First, retroactively fix any existing comments with null/blank statuses to be pending
    reversible do |dir|
      dir.up do
        execute "UPDATE comments SET status = 'pending' WHERE status IS NULL OR status = ''"
      end
    end

    # 2. Enforce the strict 'pending' default value constraint at the database layer
    change_column_default :comments, :status, from: nil, to: "pending"
  end
end