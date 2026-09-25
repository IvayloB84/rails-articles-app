class MigrateSingularImagesToPlural < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        # Natively updates the Active Storage records mapping names so old photos become visible under the new plural association instantly
        execute "UPDATE active_storage_attachments SET name = 'images' WHERE record_type = 'Article' AND name = 'image'"
      end
      dir.down do
        execute "UPDATE active_storage_attachments SET name = 'image' WHERE record_type = 'Article' AND name = 'images'"
      end
    end
  end
end