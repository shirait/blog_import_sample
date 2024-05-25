class CreateBlogCategorizations < ActiveRecord::Migration[7.1]
  def change
    create_table :blog_categorizations do |t|
      t.references :blog
      t.references :category

      t.timestamps
    end
  end
end
