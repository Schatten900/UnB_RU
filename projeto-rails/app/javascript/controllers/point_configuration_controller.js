import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["restaurantInput", "restaurantCard", "gateGroup", "gateInput", "restaurantSummary", "gateSummary", "gateCount", "submitButton"]

  connect() {
    this.updateRestaurant()
  }

  changeRestaurant() {
    const restaurant = this.selectedRestaurant()
    const visibleGroup = this.gateGroupTargets.find((group) => group.dataset.restaurantId === restaurant?.value)
    const selectedGate = this.gateInputTargets.find((gate) => gate.dataset.restaurantId === restaurant?.value)

    this.gateGroupTargets.forEach((group) => {
      group.hidden = group !== visibleGroup
    })

    if (selectedGate && !this.gateInputTargets.some((gate) => gate.checked && gate.dataset.restaurantId === restaurant.value)) {
      selectedGate.checked = true
    }

    this.updateRestaurant()
  }

  changeGate() {
    this.updateGate()
  }

  selectedRestaurant() {
    return this.restaurantInputTargets.find((input) => input.checked)
  }

  updateRestaurant() {
    const restaurant = this.selectedRestaurant()
    if (!restaurant) return

    this.restaurantCardTargets.forEach((card) => {
      card.classList.toggle("is-selected", card.dataset.restaurantId === restaurant.value)
    })
    this.restaurantSummaryTarget.textContent = restaurant.dataset.restaurantName

    const group = this.gateGroupTargets.find((item) => item.dataset.restaurantId === restaurant.value)
    const gates = this.gateInputTargets.filter((gate) => gate.dataset.restaurantId === restaurant.value)
    this.gateCountTarget.textContent = `${gates.length} ${gates.length === 1 ? "catraca" : "catracas"}`

    if (group && !gates.some((gate) => gate.checked)) {
      if (gates[0]) gates[0].checked = true
    }
    this.updateGate()
  }

  updateGate() {
    const restaurant = this.selectedRestaurant()
    const gate = this.gateInputTargets.find((input) => input.checked && input.dataset.restaurantId === restaurant?.value)
    this.gateInputTargets.forEach((input) => {
      input.closest(".gate-option")?.classList.toggle("is-selected", input === gate)
    })
    this.gateSummaryTarget.textContent = gate ? `${gate.dataset.gateLabel} · ${gate.dataset.floorLabel}` : "Nenhuma cadastrada"
    this.submitButtonTarget.disabled = !gate
  }
}