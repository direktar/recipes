require 'rails_helper'

RSpec.describe RecipeSearchForm do
  describe "validations" do
    it "is valid with a proper query" do
      form = RecipeSearchForm.new(query: "onion, garlic, tomato")

      expect(form).to be_valid
    end

    it "is valid with an empty query" do
      form = RecipeSearchForm.new(query: "")
      expect(form).to be_valid
    end

    it "is valid with a nil query" do
      form = RecipeSearchForm.new(query: nil)
      expect(form).to be_valid
    end

    it "is invalid with special characters" do
      form = RecipeSearchForm.new(query: "onion, garlic!, tomato")
      expect(form).not_to be_valid
      expect(form.errors[:query]).to include("can only contain letters, numbers, spaces, and commas")
    end

    context "ingredient format validation" do
      it "is invalid with empty ingredients between commas" do
        form = RecipeSearchForm.new(query: "onion, , tomato")
        expect(form).not_to be_valid
        expect(form.errors[:query]).to include("ingredient names cannot be empty")
      end

      it "is invalid with ingredients shorter than 2 characters" do
        form = RecipeSearchForm.new(query: "onion, a, tomato")
        expect(form).not_to be_valid
        expect(form.errors[:query]).to include("ingredient names must be at least 2 characters")
      end
    end
  end

  describe "#call" do
    context "when form is valid" do
      it "calls the RecipeSearchService with form attributes" do
        form = RecipeSearchForm.new(query: "onion, garlic")

        expect(RecipeSearchService).to receive(:call)
                                         .with(form.attributes)
                                         .and_return([])

        allow_any_instance_of(RecipeSearchForm).to receive(:binding)

        form.call
      end
    end

    context "when form is invalid" do
      it "raises an ActiveRecord::RecordInvalid error" do
        form = RecipeSearchForm.new(query: "onion, !, tomato")

        expect {
          form.call
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
