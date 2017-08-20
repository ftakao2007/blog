class Article < ApplicationRecord
  has_one :comment
  #has_many :comments
  validates :title, presence: true, length: { minimum: 5 }
end
