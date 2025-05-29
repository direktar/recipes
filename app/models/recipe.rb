# == Schema Information
#
# Table name: recipes
#
#  id               :bigint           not null, primary key
#  description      :text
#  difficulty       :string
#  instructions     :text
#  preparation_time :integer
#  title            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Recipe < ApplicationRecord
  searchkick callbacks: :async

  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  def search_data
    {
      title: title,
      title_lowercase: title.downcase,
      ingredients: ingredients.map(&:name),
      ingredients_text: ingredients.map(&:name).join(" "),
      ingredients_lowercase: ingredients.map { |i| i.name.downcase }
    }
  end

  def preparation_time_text
    if preparation_time.present?
      "#{preparation_time} #{preparation_time == 1 ? 'minute' : 'minutes'}"
    else
      "Time not specified"
    end
  end

end
