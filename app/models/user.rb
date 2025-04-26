# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :user_ingredients, dependent: :destroy
  has_many :ingredients, through: :user_ingredients

  def add_ingredient(ingredient, quantity = nil, unit = nil)
    user_ingredients.find_or_create_by(ingredient: ingredient) do |ui|
      ui.quantity = quantity if ui.respond_to?(:quantity=)
      ui.unit = unit if ui.respond_to?(:unit=)
    end
  end

  def remove_ingredient(ingredient)
    user_ingredients.where(ingredient: ingredient).destroy_all
  end

  def has_ingredient?(ingredient)
    ingredients.include?(ingredient)
  end

  def recipes_i_can_make
    Recipe.find_by_user_ingredients(self)
  end
end
