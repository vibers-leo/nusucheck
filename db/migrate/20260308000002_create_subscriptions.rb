class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.references :master, null: false, foreign_key: { to_table: :users }
      t.integer :tier, default: 0, null: false  # free, basic, premium
      t.decimal :monthly_fee, precision: 10, scale: 2, default: 0
      t.date :starts_on
      t.date :expires_on
      t.boolean :active, default: true
      t.jsonb :features, default: {}

      t.timestamps
    end

    add_index :subscriptions, :tier
    add_index :subscriptions, :active
    add_index :subscriptions, [:master_id, :active]
  end
end
