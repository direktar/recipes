FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "ingredient_#{n}" }
  end
end
