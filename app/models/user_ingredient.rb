# == Schema Information
#
# Table name: user_ingredients
#
#  id            :bigint           not null, primary key
#  quantity      :float
#  unit          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ingredient_id :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_user_ingredients_on_ingredient_id  (ingredient_id)
#  index_user_ingredients_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (ingredient_id => ingredients.id)
#  fk_rails_...  (user_id => users.id)
#
class UserIngredient < ApplicationRecord
  belongs_to :user
  belongs_to :ingredient

  validates :user_id, uniqueness: { scope: :ingredient_id }
end
