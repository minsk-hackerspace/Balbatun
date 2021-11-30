class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users, force: true do |t|
      t.integer :telegram_id, null: false, index: true
      t.integer :chat_id, null: false, index: true
      t.integer :hacker_id, index: true
      t.string :name

      t.timestamps
    end
  end
end
