class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.string :category, null: false, default: "general"
      t.integer :views_count, null: false, default: 0
      t.integer :likes_count, null: false, default: 0

      t.timestamps
    end

    add_index :posts, :category
    add_index :posts, :created_at
  end
end
