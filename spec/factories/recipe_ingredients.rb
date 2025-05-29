FactoryBot.define do
  factory :recipe_ingredient do
    recipe
    ingredient
    quantity { rand(1..10) }
    unit { %w[g ml cup tbsp tsp oz].sample }
    notes { "Optional" }
  end
end
