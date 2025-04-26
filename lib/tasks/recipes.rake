require 'nokogiri'
require 'concurrent'
require 'json'

namespace :recipes do
  desc "Import recipes from JSON file using multi-threading"
  task import: :environment do
    puts "Starting recipe import with multi-threading..."

    file_path = Rails.root.join('db', 'recipes-en.json')
    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      return
    end

    json_data = File.read(file_path)
    recipes_data = JSON.parse(json_data)
    puts "Found #{recipes_data.size} recipes in the JSON file."

    # Кількість потоків для обробки
    thread_count = [Concurrent.processor_count - 1, 1].max
    puts "Using #{thread_count} threads for processing"

    # Створюємо пул потоків
    pool = Concurrent::FixedThreadPool.new(thread_count)

    # Лічильники для статистики
    successful_imports = Concurrent::AtomicFixnum.new(0)
    created_ingredients = Concurrent::AtomicFixnum.new(0)
    skipped_ingredients = Concurrent::AtomicFixnum.new(0)

    # Розбиваємо рецепти на групи для обробки в різних потоках
    recipes_data.each do |recipe_data|
      pool.post do
        process_recipe(recipe_data, successful_imports, created_ingredients, skipped_ingredients)
      end
    end

    # Очікуємо завершення всіх потоків
    pool.shutdown
    pool.wait_for_termination

    puts "Recipe import complete!"
    puts "Successfully imported #{successful_imports.value} recipes"
    puts "Created #{created_ingredients.value} unique ingredients"
    puts "Skipped #{skipped_ingredients.value} invalid ingredients"
  end

  private

  def process_recipe(recipe_data, successful_imports, created_ingredients, skipped_ingredients)
    recipe_title = recipe_data['title'] || ''
    if recipe_title.blank?
      puts "Skipping recipe without title: #{recipe_data.inspect[0..100]}..."
      return
    end

    preparation_time = nil
    if recipe_data['prep_time'].present? || recipe_data['cook_time'].present?
      prep_time = recipe_data['prep_time'].to_i
      cook_time = recipe_data['cook_time'].to_i
      preparation_time = prep_time + cook_time if prep_time > 0 || cook_time > 0
    end

    begin
      recipe = nil

      ActiveRecord::Base.transaction do
        recipe = Recipe.create!(
          title: recipe_title,
          description: recipe_data['description'] || '',
          instructions: recipe_data['directions'] || '',
          preparation_time: preparation_time,
          difficulty: recipe_data['difficulty'] || calculate_difficulty(preparation_time)
        )

        if recipe_data['ingredients'].is_a?(Array)
          recipe_data['ingredients'].each do |ingredient_text|
            next if ingredient_text.blank?

            quantity, unit, name, notes = parse_ingredient(ingredient_text)

            if name.blank?
              skipped_ingredients.increment
              next
            end

            # Створення або пошук інгредієнта з механізмом блокування
            begin
              ingredient = nil

              # Використовуємо блокування бази даних для запобігання дублювання
              Ingredient.transaction do
                ingredient = Ingredient.find_by(name: name)

                if ingredient.nil?
                  ingredient = Ingredient.create!(name: name)
                  created_ingredients.increment
                end
              end

              RecipeIngredient.create!(
                recipe: recipe,
                ingredient: ingredient,
                quantity: quantity,
                unit: unit,
                notes: notes
              )
            rescue => e
              puts "  Error processing ingredient '#{name}': #{e.message}"
            end
          end
        end
      end

      successful_imports.increment

      if successful_imports.value % 50 == 0
        puts "Progress: #{successful_imports.value} recipes processed..."
      end

    rescue => e
      puts "Error creating recipe '#{recipe_title}': #{e.message}"
    end
  end

  def calculate_difficulty(prep_time)
    return 'medium' if prep_time.nil?

    if prep_time < 30
      'easy'
    elsif prep_time < 60
      'medium'
    else
      'hard'
    end
  end

  def parse_ingredient(text)
    return [nil, nil, nil, nil] if text.blank?

    text = text.strip
    quantity = nil
    unit = nil
    name = text
    notes = nil

    if match = text.match(/^([\d½¼¾⅓⅔\.\/\s]+)\s+(tbsp|tbs|tablespoon|tablespoons|tsp|teaspoon|teaspoons|cup|cups|oz|ounce|ounces|pound|pounds|lb|lbs|gram|grams|g|kg|kilogram|kilograms|ml|milliliter|milliliters|l|liter|liters|pinch|pinches|dash|dashes|can|cans|package|packages|bottle|bottles|clove|cloves|slice|slices)\s+(.+?)(?:\s*,\s*(.+))?$/i)
      quantity = parse_quantity(match[1])
      unit = normalize_unit(match[2])
      name = match[3].strip
      notes = match[4]&.strip
    elsif match = text.match(/^(.+?)(?:\s*,\s*(.+))?$/i)
      name = match[1].strip
      notes = match[2]&.strip
    end

    [quantity, unit, name, notes]
  end

  def parse_quantity(quantity_text)
    return nil if quantity_text.blank?

    # Обробка спеціальних символів дробів
    quantity_text = quantity_text.gsub('½', '1/2')
                                 .gsub('¼', '1/4')
                                 .gsub('¾', '3/4')
                                 .gsub('⅓', '1/3')
                                 .gsub('⅔', '2/3')

    if quantity_text.include?('/')
      if quantity_text.include?(' ')
        # Мішаний дріб (1 1/2)
        whole, fraction = quantity_text.split(' ', 2)
        numerator, denominator = fraction.split('/')
        return whole.to_f + (numerator.to_f / denominator.to_f)
      else
        numerator, denominator = quantity_text.split('/')
        return numerator.to_f / denominator.to_f
      end
    end

    quantity_text.to_f
  end

  def normalize_unit(unit)
    return nil unless unit.present?

    case unit.downcase
    when 'tablespoon', 'tablespoons', 'tbsp', 'tbs'
      'tablespoon'
    when 'teaspoon', 'teaspoons', 'tsp'
      'teaspoon'
    when 'cup', 'cups'
      'cup'
    when 'ounce', 'ounces', 'oz'
      'ounce'
    when 'pound', 'pounds', 'lb', 'lbs'
      'pound'
    when 'gram', 'grams', 'g'
      'gram'
    when 'kilogram', 'kilograms', 'kg'
      'kilogram'
    when 'milliliter', 'milliliters', 'ml'
      'milliliter'
    when 'liter', 'liters', 'l'
      'liter'
    when 'pinch', 'pinches'
      'pinch'
    when 'dash', 'dashes'
      'dash'
    when 'can', 'cans'
      'can'
    when 'package', 'packages'
      'package'
    when 'bottle', 'bottles'
      'bottle'
    when 'clove', 'cloves'
      'clove'
    when 'slice', 'slices'
      'slice'
    else
      unit.downcase
    end
  end
end

# Додаткове завдання для імпорту базових інгредієнтів
namespace :ingredients do
  desc "Import basic ingredients"
  task import_basic: :environment do
    puts "Importing basic ingredients..."

    basic_ingredients = [
      "salt", "pepper", "olive oil", "butter", "garlic", "onion",
      "flour", "sugar", "eggs", "milk", "chicken", "beef",
      "rice", "pasta", "tomatoes", "potatoes", "carrots",
      "cheese", "broccoli", "lemon", "cream", "basil", "thyme",
      "rosemary", "spinach", "mushrooms", "bell pepper"
    ]

    created_count = 0
    basic_ingredients.each do |name|
      if Ingredient.find_or_create_by(name: name)
        created_count += 1
      end
    end

    puts "Imported #{created_count} basic ingredients."
  end
end



#
# namespace :import do
#   desc "Import recipes from JSON file"
#   task recipes: :environment do
#     require 'json'
#
#     puts "Starting recipe import..."
#
#     file_path = Rails.root.join('db', 'recipes-en.json')
#     unless File.exist?(file_path)
#       puts "Error: File not found at #{file_path}"
#       exit
#     end
#
#     json_data = File.read(file_path)
#     recipes_data = JSON.parse(json_data)
#     puts "Found #{recipes_data.size} recipes in the JSON file."
#
#     created_recipes = 0
#     created_ingredients = 0
#     skipped_ingredients = 0
#
#     Recipe.transaction do
#       recipes_data.each do |recipe_data|
#         recipe_title = recipe_data['title'] || ''
#         if recipe_title.blank?
#           puts "Skipping recipe without title: #{recipe_data.inspect[0..100]}..."
#           next
#         end
#
#         preparation_time = nil
#         if recipe_data['prep_time'].present? || recipe_data['cook_time'].present?
#           prep_time = recipe_data['prep_time'].to_i
#           cook_time = recipe_data['cook_time'].to_i
#           preparation_time = prep_time + cook_time if prep_time > 0 || cook_time > 0
#         end
#
#         begin
#           recipe = Recipe.create!(
#             title: recipe_title,
#             description: recipe_data['description'] || '',
#             instructions: recipe_data['directions'] || '',
#             preparation_time: preparation_time,
#             difficulty: recipe_data['difficulty'] || calculate_difficulty(preparation_time)
#           )
#           created_recipes += 1
#           puts "Created recipe ##{created_recipes}: #{recipe.title}"
#
#           if recipe_data['ingredients'].is_a?(Array)
#             recipe_data['ingredients'].each do |ingredient_text|
#               next if ingredient_text.blank?
#
#               quantity, unit, name, notes = parse_ingredient(ingredient_text)
#
#               if name.blank?
#                 skipped_ingredients += 1
#                 next
#               end
#
#               # Створення або пошук інгредієнта
#               begin
#                 ingredient = Ingredient.find_or_create_by!(name: name)
#                 created_ingredients += 1 if ingredient.new_record?
#
#                 RecipeIngredient.create!(
#                   recipe: recipe,
#                   ingredient: ingredient,
#                   quantity: quantity,
#                   unit: unit,
#                   notes: notes
#                 )
#               rescue => e
#                 puts "  Error processing ingredient '#{name}': #{e.message}"
#               end
#             end
#           end
#         rescue => e
#           puts "Error creating recipe '#{recipe_title}': #{e.message}"
#         end
#
#         if created_recipes % 50 == 0
#           puts "Progress: #{created_recipes} recipes processed..."
#         end
#       end
#     end
#
#     puts "Import completed!"
#     puts "Created #{created_recipes} recipes"
#     puts "Created #{created_ingredients} unique ingredients"
#     puts "Skipped #{skipped_ingredients} invalid ingredients"
#   end
#
#   def calculate_difficulty(prep_time)
#     return 'medium' if prep_time.nil?
#
#     if prep_time < 30
#       'easy'
#     elsif prep_time < 60
#       'medium'
#     else
#       'hard'
#     end
#   end
#
#   def parse_ingredient(text)
#     return [nil, nil, nil, nil] if text.blank?
#
#     text = text.strip
#     quantity = nil
#     unit = nil
#     name = text
#     notes = nil
#
#     if match = text.match(/^([\d½¼¾⅓⅔\.\/\s]+)\s+(tbsp|tbs|tablespoon|tablespoons|tsp|teaspoon|teaspoons|cup|cups|oz|ounce|ounces|pound|pounds|lb|lbs|gram|grams|g|kg|kilogram|kilograms|ml|milliliter|milliliters|l|liter|liters|pinch|pinches|dash|dashes|can|cans|package|packages|bottle|bottles|clove|cloves|slice|slices)\s+(.+?)(?:\s*,\s*(.+))?$/i)
#       quantity = parse_quantity(match[1])
#       unit = normalize_unit(match[2])
#       name = match[3].strip
#       notes = match[4]&.strip
#       # Шаблон для "salt and pepper, to taste"
#     elsif match = text.match(/^(.+?)(?:\s*,\s*(.+))?$/i)
#       name = match[1].strip
#       notes = match[2]&.strip
#     end
#
#     [quantity, unit, name, notes]
#   end
#
#   def parse_quantity(quantity_text)
#     return nil if quantity_text.blank?
#
#     # Обробка спеціальних символів дробів
#     quantity_text = quantity_text.gsub('½', '1/2')
#                                  .gsub('¼', '1/4')
#                                  .gsub('¾', '3/4')
#                                  .gsub('⅓', '1/3')
#                                  .gsub('⅔', '2/3')
#
#     if quantity_text.include?('/')
#       if quantity_text.include?(' ')
#         # Мішаний дріб (1 1/2)
#         whole, fraction = quantity_text.split(' ', 2)
#         numerator, denominator = fraction.split('/')
#         return whole.to_f + (numerator.to_f / denominator.to_f)
#       else
#         numerator, denominator = quantity_text.split('/')
#         return numerator.to_f / denominator.to_f
#       end
#     end
#
#     quantity_text.to_f
#   end
#
#   def normalize_unit(unit)
#     return nil unless unit.present?
#
#     case unit.downcase
#     when 'tablespoon', 'tablespoons', 'tbsp', 'tbs'
#       'tablespoon'
#     when 'teaspoon', 'teaspoons', 'tsp'
#       'teaspoon'
#     when 'cup', 'cups'
#       'cup'
#     when 'ounce', 'ounces', 'oz'
#       'ounce'
#     when 'pound', 'pounds', 'lb', 'lbs'
#       'pound'
#     when 'gram', 'grams', 'g'
#       'gram'
#     when 'kilogram', 'kilograms', 'kg'
#       'kilogram'
#     when 'milliliter', 'milliliters', 'ml'
#       'milliliter'
#     when 'liter', 'liters', 'l'
#       'liter'
#     when 'pinch', 'pinches'
#       'pinch'
#     when 'dash', 'dashes'
#       'dash'
#     when 'can', 'cans'
#       'can'
#     when 'package', 'packages'
#       'package'
#     when 'bottle', 'bottles'
#       'bottle'
#     when 'clove', 'cloves'
#       'clove'
#     when 'slice', 'slices'
#       'slice'
#     else
#       unit.downcase
#     end
#   end
# end
