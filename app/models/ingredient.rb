# == Schema Information
#
# Table name: ingredients
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients

  has_many :user_ingredients, dependent: :destroy
  has_many :users, through: :user_ingredients

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_save :normalize_name

  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
