class BlogCategorization < ApplicationRecord
  belongs_to :blog
  belongs_to :category

  def self.category_selectbox_attributes_for_blogs_index
    categories_name_count_id = BlogCategorization.joins(:category).group('blog_categorizations.category_id')
                                                 .pluck('categories.name', 'count(blog_categorizations.category_id)', 'blog_categorizations.category_id')

    categories_name_count_id.map do |name, count, id|
      ["#{name}(件数:#{count})", id]
    end
  end
end
