class Category < ApplicationRecord
  has_many :blog_categorizations, dependent: :destroy
  has_many :blog, through: :blog_categorizations

  validates :name, presence: true

  def self.upsert_categories(blog_import_log)
    categories_ary = []
    CSV.parse(blog_import_log.file_body, headers: true) do |row|
      categories_ary |= row[2].split(',').map(&:strip).select(&:present?)
    end
    categories_hash = categories_ary.map{|name| {name: name}}
    Category.upsert_all(categories_hash, on_duplicate: :update)
  end
end
