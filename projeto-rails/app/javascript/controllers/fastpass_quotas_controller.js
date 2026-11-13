import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "total", "daily"]
  connect() { this.updateTotal() }
  distribute() {
    if (!this.hasDailyTarget || !this.rowTargets.length) return
    this.dailyTarget.setCustomValidity("")
    if (!this.dailyTarget.validity.valid) return
    const total = Number(this.dailyTarget.value)
    this.rowTargets.forEach((row, index) => this.updateRow(row, Math.floor(total / this.rowTargets.length) + (index < total % this.rowTargets.length ? 1 : 0)))
    this.updateTotal()
  }
  increase(event) { this.adjust(event, 1) }
  decrease(event) { this.adjust(event, -1) }
  adjust(event, delta) {
    const row = event.currentTarget.closest("tr")
    this.updateRow(row, Math.max(0, Number(row.querySelector("[data-quota-value]").value) + delta))
    this.updateTotal()
  }
  updateRow(row, quota) { row.querySelector("[data-quota-value]").value = quota }
  updateTotal() {
    if (!this.hasTotalTarget || !this.hasDailyTarget) return
    let total = 0
    this.rowTargets.forEach(row => {
      const value = Number(row.querySelector("[data-quota-value]").value)
      total += value
      row.querySelector("[data-quota-label]").textContent = value
      row.querySelector('button[data-action="fastpass-quotas#decrease"]').disabled = value === 0
    })
    this.totalTarget.textContent = total
    this.dailyTarget.setCustomValidity(total === Number(this.dailyTarget.value) ? "" : "A soma das cotas deve ser igual à cota diária.")
  }
}
