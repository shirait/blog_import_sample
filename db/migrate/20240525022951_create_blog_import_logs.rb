class CreateBlogImportLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :blog_import_logs do |t|
      t.string  :file_name, null: false
      t.text    :file_body, limit: 4294967295 # longtext型にする
      t.integer :result,    default: 0
      t.text    :message

      t.timestamps
    end
  end
end
