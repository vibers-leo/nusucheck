class AddMetadataToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :message_category, :integer, default: 0, null: false
    add_column :messages, :metadata, :jsonb, default: {}

    add_index :messages, :message_category
    add_index :messages, :metadata, using: :gin
  end
end
