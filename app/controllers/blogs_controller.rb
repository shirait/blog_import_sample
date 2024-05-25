require 'csv'

class BlogsController < ApplicationController
  def index
  end

  def select_csv
  end

  class InvalidError < RuntimeError; end

  def import_csv
    if params[:csv].blank?
      flash[:danger] = 'csvを選択してください。'
      render :select_csv and return
    end

    @blog_import_log = BlogImportLog.create_blog_import_log!(params[:csv])

    ActiveRecord::Base.transaction do
      validate_duplicate_title!

      Category.upsert_categories(@blog_import_log)

      blogs = prepare_blogs
      validate_blogs!(blogs)
      Blog.import(blogs, validate: false)

      BlogCategorization.insert_all(prepare_blog_categorizations(blogs))

      @blog_import_log.result = :success
      flash[:success] = 'CSVを登録しました。'
    rescue InvalidError => e
      @blog_import_log.result = :invalid_error
      @blog_import_log.message = e
      flash[:danger] = "CSVの登録に失敗しました。#{line_break}#{e}"
    rescue Exception => e
      @blog_import_log.result = :unexpected_error
      @blog_import_log.message = ([e] + e.backtrace).join(line_break)
      flash[:danger] = "CSVの登録に失敗しました。#{line_break}#{e}"
    ensure
      @blog_import_log.save
      redirect_to(select_csv_blogs_path)
    end
  end

  private

  def line_break
    "\r\n"
  end

  def number_of_error_display
    10
  end

  # CSV内でのブログタイトルの重複チェック。
  # DBに保存されたタイトルとの重複チェックはBlogクラスのバリデーションに定義。
  def validate_duplicate_title!
    return if duplicate_titles.blank?
    raise(InvalidError, (['以下のタイトルが重複しています。'] + duplicate_titles).join(line_break))
  end

  def duplicate_titles
    titles = []
    CSV.parse(@blog_import_log.file_body, headers: true) do |row|
      titles << row[0].to_s.strip
    end
    titles.select{|title| titles.count(title) > 1 }.uniq
  end

  def prepare_blogs
    all_categories = Category.pluck(:name, :id).to_h
    blogs = []
    id = (Blog.maximum(:id) || 0) + 1

    CSV.parse(@blog_import_log.file_body, headers: true) do |csv_row|
      blogs << Blog.initialize_blog_from_csv_row(id, csv_row, all_categories, @blog_import_log)
      id += 1
    end

    blogs
  end

  def validate_blogs!(blogs)
    error_messages = []
    line_number = 2

    blogs.each do |blog|
      next if blog.valid?
      error_messages << "#{line_number}行目: #{blog.errors.full_messages}"
      break if number_of_error_display <= error_messages.size
      line_number += 1
    end

    return if error_messages.blank?
    raise(InvalidError, error_messages.join(line_break))
  end

  def prepare_blog_categorizations(blogs)
    blog_categorizations = []
    blogs.each do |blog|
      blog_categorizations +=
        blog.category_ids_for_csv_import.map{|category_id| {blog_id: blog.id, category_id: category_id}}
    end
    blog_categorizations
  end
end