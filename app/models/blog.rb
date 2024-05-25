class Blog < ApplicationRecord
  belongs_to :blog_import_log
  has_many :blog_categorizations, dependent: :destroy
  has_many :categories, through: :blog_categorizations

  validates :title,      presence: true, uniqueness: true
  validates :content,    presence: true
  validates :good_count, presence: true

  attr_accessor :category_ids_for_csv_import

  def self.initialize_blog_from_csv_row(id, csv_row, all_categories, blog_import_log)
    category_names = csv_row[2].split(',').map(&:strip)

    blog = Blog.new(
      id:                          id,
      blog_import_log_id:          blog_import_log.id,
      title:                       csv_row[0].to_s,
      content:                     csv_row[1].to_s,
      # 「category_ids_for_csv_import: Category.where(name: category_names),」と書くとパフォーマンスが悪くなる。
      category_ids_for_csv_import: category_names.map{ |name| all_categories[name] },
      good_count:                  csv_row[3].to_i,
      created_at:                  csv_row[4],
      updated_at:                  csv_row[5],
    )

    blog
  end
end