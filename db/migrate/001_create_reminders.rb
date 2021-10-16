class CreateReminders < ActiveRecord::Migration[5.1]
  def change
    create_table :reminders, force: true do |t|
      t.integer :chat_id
      t.datetime :time
      t.string :text

      t.timestamps
    end
  end
end
