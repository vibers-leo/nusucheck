class CreateExpertInquiries < ActiveRecord::Migration[7.1]
  def change
    create_table :expert_inquiries do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.string :email
      t.text :message
      t.string :status, default: "pending", null: false  # pending / approved / rejected
      t.datetime :approved_at
      t.text :approval_notes

      t.timestamps
    end

    add_index :expert_inquiries, :status
    add_index :expert_inquiries, :created_at
  end
end
