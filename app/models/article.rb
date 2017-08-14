class Article < ApplicationRecord
  has_many :comments
  validates :title, presence: true, length: { minimum: 5 }
  mount_uploader :image, ImageUploader
end
