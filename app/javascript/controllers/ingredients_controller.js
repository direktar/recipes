import { Controller } from "@hotwired/stimulus"

// Manages dynamic ingredient fields for recipes
export default class extends Controller {
  static targets = ["container", "template"]

  connect() {
    console.log("Ingredients controller connected")
  }

  addNewIngredient(event) {
    event.preventDefault()

    // Get the template and create a new row with unique ID
    const template = this.templateTarget.innerHTML
    const timestamp = new Date().getTime()
    const newRow = template.replace(/_NEW_/g, `new_${timestamp}`)

    // Add the new row to the container
    this.containerTarget.insertAdjacentHTML('beforeend', newRow)

    // Focus the ingredient select in the new row
    const newSelect = this.containerTarget.querySelector(`.ingredient-row[data-id="new_${timestamp}"] .ingredient-select`)
    if (newSelect) {
      newSelect.focus()
    }
  }

  removeIngredient(event) {
    event.preventDefault()

    // Find the parent ingredient row and remove it
    const row = event.target.closest('.ingredient-row')

    // Add a hidden _destroy field if this is an existing record
    const rowId = row.dataset.id
    if (rowId && !rowId.startsWith('new_')) {
      const destroyField = document.createElement('input')
      destroyField.type = 'hidden'
      destroyField.name = `recipe[recipe_ingredients_attributes][${rowId}][_destroy]`
      destroyField.value = '1'
      this.containerTarget.appendChild(destroyField)
    }

    row.remove()
  }
}
