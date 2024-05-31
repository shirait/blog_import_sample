class BlogImportLog < ApplicationRecord
  has_many :blogs, dependent: :restrict_with_exception

  enum result: { before_process: 0, success: 1, invalid_error: 2, unexpected_error: 3 }

  validates :file_name, presence: true
  validates :file_body, presence: true

  def self.create_blog_import_log!(csv)
    BlogImportLog.create!(
      file_name: csv.original_filename,
      # force_encodingしないと、文字コードが'ascii-8bit'となることに注意。
      # 変換できない文字が含まれていた場合の挙動は要検討。（エラーにする、空文字等に変更する、など）
      file_body: csv.read.force_encoding('UTF-8'),
      result:    :before_process,
    )
  end
end
