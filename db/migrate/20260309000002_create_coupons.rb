class CreateCoupons < ActiveRecord::Migration[7.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :name, null: false
      t.text :description
      t.string :coupon_type, null: false # percentage, fixed_amount
      t.decimal :discount_value, precision: 10, scale: 2, null: false
      t.decimal :min_amount, precision: 10, scale: 2 # 최소 결제 금액
      t.decimal :max_discount, precision: 10, scale: 2 # 최대 할인 금액
      t.datetime :valid_from
      t.datetime :valid_until
      t.integer :usage_limit # 전체 사용 가능 횟수
      t.integer :usage_count, default: 0 # 현재까지 사용된 횟수
      t.boolean :active, default: true

      t.timestamps
    end

    create_table :user_coupons do |t|
      t.references :user, null: false, foreign_key: true
      t.references :coupon, null: false, foreign_key: true
      t.boolean :used, default: false
      t.datetime :used_at
      t.references :request, foreign_key: true # 어떤 체크에 사용했는지

      t.timestamps
    end

    add_index :user_coupons, [:user_id, :coupon_id], unique: true
  end
end
