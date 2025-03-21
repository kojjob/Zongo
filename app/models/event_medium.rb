class EventMedium < ApplicationRecord
  belongs_to :event
  belongs_to :user
  has_one_attached :file

  # Enumeration for media types
  enum :media_type, {
    image: 0,
    video: 1,
    document: 2,
    audio: 3,
    other: 4
  }, default: :other, prefix: true

  # Validations
  validates :media_type, presence: true
  validate :file_attachment_presence
  validate :file_content_type

  # Scopes
  scope :featured, -> { where(is_featured: true).order(display_order: :asc, created_at: :desc) }
  scope :images, -> { where(media_type: :image) }
  scope :videos, -> { where(media_type: :video) }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }

  # Methods
  def image?
    media_type == "image"
  end

  def video?
    media_type == "video"
  end

  def document?
    media_type == "document"
  end

  def audio?
    media_type == "audio"
  end

  def feature!
    update(is_featured: true)
  end

  def unfeature!
    update(is_featured: false)
  end

  def mime_type
    file.attachment&.blob&.content_type
  end

  def filename
    file.attachment&.blob&.filename.to_s
  end

  def filesize
    file.attachment&.blob&.byte_size
  end

  def formatted_filesize
    return nil unless filesize

    if filesize < 1024
      "#{filesize} bytes"
    elsif filesize < 1024 * 1024
      "#{(filesize.to_f / 1024).round(1)} KB"
    elsif filesize < 1024 * 1024 * 1024
      "#{(filesize.to_f / (1024 * 1024)).round(1)} MB"
    else
      "#{(filesize.to_f / (1024 * 1024 * 1024)).round(1)} GB"
    end
  end

  private

  def file_attachment_presence
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_content_type
    return unless file.attached?

    case media_type
    when "image"
      unless file.content_type.start_with?("image/")
        errors.add(:file, "must be an image")
      end
    when "video"
      unless file.content_type.start_with?("video/")
        errors.add(:file, "must be a video")
      end
    when "document"
      valid_types = [ "application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ]
      unless valid_types.include?(file.content_type)
        errors.add(:file, "must be a document (PDF, DOC, DOCX)")
      end
    when "audio"
      unless file.content_type.start_with?("audio/")
        errors.add(:file, "must be an audio file")
      end
    end
  end
end
