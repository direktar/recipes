class RecipeSearchForm
  include ActiveAttr::Model

  attribute :query, type: String

  validates :query, format: {
    with: /\A[a-zA-Z0-9\s,]+\z/,
    message: "can only contain letters, numbers, spaces, and commas",
    allow_blank: true
  }

  validate :validate_ingredient_format

  def call
    raise ActiveRecord::RecordInvalid, self unless valid?

    ::RecipeSearchService.call(attributes)
  end


  private

  def validate_ingredient_format
    return if query.blank?

    ingredients = query.split(",").map(&:strip)

    if ingredients.any?(&:blank?)
      errors.add(:query, "ingredient names cannot be empty")
    end

    if ingredients.any? { |i| i.length < 2 }
      errors.add(:query, "ingredient names must be at least 2 characters")
    end
  end
end
