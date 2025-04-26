if Recipe.count == 0
  puts "🥘 Importing recipes (this may take some time)..."
  Rake::Task["recipes:import"].invoke rescue puts "⚠️ Recipe import failed, continuing with other seed data"
end

puts "🌱 Starting seed data generation..."

puts "Cleaning up existing user data..."
UserIngredient.destroy_all
User.destroy_all

DEMO_EMAIL = "demo@example.com"
DEMO_PASS  = "password123"

User.create!(
  email: DEMO_EMAIL,
  password: DEMO_PASS,
  password_confirmation: DEMO_PASS
)
puts "✅ Demo user created: #{DEMO_EMAIL} / #{DEMO_PASS}"

5.times do |i|
  email = "user#{i+1}@example.com"
  password = DEMO_PASS

  User.create!(
    email: email,
    password: password,
    password_confirmation: password
  )
  puts "👤 Created random user: #{email} / #{password}"
end

ingredient_ids = Ingredient.pluck(:id)

User.find_each do |user|
  num_ingredients = rand(50..70)

  selected_ingredient_ids = ingredient_ids.sample(num_ingredients)

  puts "🧪 Adding #{num_ingredients} ingredients to user #{user.email}..."

  selected_ingredient_ids.each do |ingredient_id|
    ingredient = Ingredient.find(ingredient_id)

    quantity = rand(5..15)

    units = ["cup", "tablespoon", "teaspoon", "gram", "kilogram", "ounce", "pound", nil]
    unit = units.sample

    user.add_ingredient(ingredient, quantity, unit)

    puts "  - Added #{quantity} #{unit} of #{ingredient.name}"
  end
end

total_users = User.count
total_ingredients = Ingredient.count
total_user_ingredients = UserIngredient.count

puts "\n🎉 Seed completed successfully!"
puts "📊 Summary:"
puts "  - Users: #{total_users}"
puts "  - Total ingredients: #{total_ingredients}"
