json.extract! recipe, :id, :title, :instructions, :cook_time, :prep_time, :image_url, :rating, :category, :author, :created_at, :updated_at
json.url recipe_url(recipe, format: :json)
