class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :amount
      t.integer :payment_method
      t.integer :status
      t.string :pix_code

      t.timestamps
    end
  end
end
