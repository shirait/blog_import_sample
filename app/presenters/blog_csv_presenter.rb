require 'csv'

class BlogCsvPresenter

  LINE_BREAK = "\r\n".freeze

  NUMBER_OF_ERROR_DISPLAY = 10

  class InvalidError < RuntimeError; end

  def self.do_import_csv(csv, flash)
    blog_import_log = BlogImportLog.create_blog_import_log!(csv)

    ActiveRecord::Base.transaction do
      validate_duplicate_title!(blog_import_log)

      Category.upsert_categories(blog_import_log)

      blogs = prepare_blogs(blog_import_log)
      validate_blogs!(blogs)
      Blog.import(blogs, validate: false)

      BlogCategorization.insert_all(prepare_blog_categorizations(blogs))

      blog_import_log.result = :success
      flash[:success] = 'csvを登録しました。'
    rescue InvalidError => e
      blog_import_log.result = :invalid_error
      blog_import_log.message = e
      flash[:danger] = "csvの登録に失敗しました。#{LINE_BREAK}#{e}"
    rescue => e
      blog_import_log.result = :unexpected_error
      blog_import_log.message = ([e] + e.backtrace).join(LINE_BREAK)
      flash[:danger] = "csvの登録に失敗しました。#{LINE_BREAK}#{e}"
    ensure
      blog_import_log.save
    end
  end

  # csv内でのブログタイトルの重複チェック。
  # DBに保存されたタイトルとの重複チェックはBlogクラスのバリデーションに定義。
  def self.validate_duplicate_title!(blog_import_log)
    return if duplicate_titles(blog_import_log).blank?

    raise(InvalidError, (['以下のタイトルが重複しています。'] + duplicate_titles(blog_import_log)).join(LINE_BREAK))
  end

  def self.duplicate_titles(blog_import_log)
    titles = []
    CSV.parse(
      blog_import_log.file_body.encode(Encoding::UTF_8, invalid: :replace, undef: :replace,
                                                        universal_newline: true), headers: true
    ) do |row|
      titles << row[0].to_s.strip
    end
    titles.select { |title| titles.count(title) > 1 }.uniq
  end

  def self.prepare_blogs(blog_import_log)
    all_categories = Category.pluck(:name, :id).to_h
    blogs = []
    id = (Blog.maximum(:id) || 0) + 1

    CSV.parse(blog_import_log.file_body, headers: true) do |csv_row|
      blogs << Blog.initialize_blog_from_csv_row(id, csv_row, all_categories, blog_import_log)
      id += 1
    end

    blogs
  end

  def self.validate_blogs!(blogs)
    error_messages = []
    line_number = 2

    blogs.each do |blog|
      next if blog.valid?

      error_messages << "#{line_number}行目: #{blog.errors.full_messages}"
      break if NUMBER_OF_ERROR_DISPLAY <= error_messages.size

      line_number += 1
    end

    return if error_messages.blank?

    raise(InvalidError, error_messages.join(LINE_BREAK))
  end

  def self.prepare_blog_categorizations(blogs)
    blog_categorizations = []
    blogs.each do |blog|
      blog_categorizations +=
        blog.category_ids_for_csv_import.map { |category_id| { blog_id: blog.id, category_id: } }
    end
    blog_categorizations
  end
end
