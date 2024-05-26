module BlogsHelper
  def data_present?
    @category_selectbox_options.present? || @blogs.present?
  end
end
