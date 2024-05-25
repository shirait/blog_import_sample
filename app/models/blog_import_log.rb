class BlogImportLog < ApplicationRecord
  has_many :blogs, dependent: :restrict_with_exception

  enum result: { before_process: 0, success: 1, invalid_error: 2, unexpected_error: 3 }

  validates :file_name, presence: true
  validates :file_body, presence: true

  def self.create_blog_import_log!(csv)
    BlogImportLog.create!(
      file_name: csv.original_filename,
      file_body: csv.read,
      result:    :before_process,
    )
    BlogImportLog.last
  end
end
