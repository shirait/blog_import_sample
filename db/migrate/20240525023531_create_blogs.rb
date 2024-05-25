class CreateBlogs < ActiveRecord::Migration[7.1]
  def change
    create_table :blogs do |t|
      t.references :blog_import_log
      t.string     :title
      t.text       :content
      t.integer    :good_count

      t.timestamps
    end

    add_index :blogs, :title, unique: true
    add_index :blogs, :good_count
  end
end
