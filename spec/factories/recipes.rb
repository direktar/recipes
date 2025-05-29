FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "Recipe #{n}" }
    description { "A delicious recipe" }
    instructions { "Step 1: Cook it\nStep 2: Eat it" }
    preparation_time { 30 }
    difficulty { %w[easy medium hard].sample }
  end
end
