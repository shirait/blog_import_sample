class BlogsController < ApplicationController
  helper_method :sort_condition

  def index
    @blogs = Blog.category_select(params[:category_ids]).eager_load(:categories).page(params[:page]).order(sort_key)
    @category_selectbox_options = BlogCategorization.category_selectbox_attributes_for_blogs_index
  end

  def select_csv; end

  def import_csv
    if params[:csv].blank?
      flash[:danger] = 'csvを選択してください。'
      render :select_csv and return
    end

    # flashメッセージを引数で渡すのは良いのか。もっとやりようがあるかもしれない。
    BlogCsvPresenter.do_import_csv(params[:csv], flash)
    redirect_to(select_csv_blogs_path)
  end

  def destroy_all
    [BlogCategorization, Blog, Category, BlogImportLog].each do |m|
      m.delete_all
    end
    flash[:danger] = 'データをすべて削除しました。'
    redirect_to(select_csv_blogs_path)
  end

  private

  def sort_key
    return 'blogs.id asc' if params[:sort_key].blank?

    # 画面から渡された文字列をそのままorderの引数に渡すのは危険。想定しない値は無視する。
    return 'blogs.id asc' unless params[:sort_key].in?(sort_condition.keys.map(&:to_s))

    params[:sort_key]
  end

  def sort_condition
    {
      'blogs.id asc' => 'ブログIDの昇順',
      'good_count asc' => 'いいねの昇順',
      'good_count desc' => 'いいねの降順'
    }
  end
end
