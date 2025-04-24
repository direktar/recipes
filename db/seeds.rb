# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# require 'json'
User.destroy_all

if Recipe.count == 0
  file = File.read(Rails.root.join("db", "recipes-en.json"))
  recipes = JSON.parse(file)

  recipes.find_each do |data|
    recipe = Recipe.create!(
      title: data["title"],
      prep_time: data["prep_time"],
      cook_time: data["cook_time"],
      image_url: data["image"],
      rating: data["ratings"],
      category: data["category"]
    )

    data["ingredients"].find_each do |ingredient_line|
      name = ingredient_line.split(",").first.split(" ").last.downcase
      ingredient = Ingredient.find_or_create_by(name: name)
      RecipeIngredient.create!(recipe:, ingredient:, raw_text: ingredient_line)
    end
  end
end

DEMO_EMAIL = "demo@example.com"
DEMO_PASS  = "password123"

demo = User.find_or_initialize_by(email: DEMO_EMAIL)
demo.password = DEMO_PASS
demo.password_confirmation = DEMO_PASS
demo.save!
puts "✅ Demo user created: #{DEMO_EMAIL} / #{DEMO_PASS}"

5.times do
  email = FFaker::Internet.unique.email
  pass  = "secret#{rand(1000..9999)}"
  User.create!(email:, password: pass, password_confirmation: pass)
end
puts "✅ Random users created: #{User.count - 1} extra"

ingredient_ids = Ingredient.pluck(:id)
abort "❌ Seed ingredients first!" if ingredient_ids.empty?

User.find_each do |user|
  sample_ids = ingredient_ids.sample(8)
  sample_ids.each do |ing_id|
    UserIngredient.find_or_create_by!(user_id: user.id, ingredient_id: ing_id)
  end
end
puts "✅ Pantry items assigned (8 per user)"
