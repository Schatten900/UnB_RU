import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "total"]

  increase(event) {
    this.adjust(event, 1)
  }

  decrease(event) {
    this.adjust(event, -1)
  }

  adjust(event, delta) {
    const row = event.currentTarget.closest("tr")
    this.updateRow(row, Math.max(0, Number(row.querySelector("[data-quota-value]").value) + delta))
    this.updateTotal()
  }

  reset() {
    this.rowTargets.forEach(row => this.updateRow(row, Number(row.dataset.defaultQuota)))
    this.updateTotal()
  }

  updateRow(row, quota) {
    row.querySelector("[data-quota-value]").value = quota
    row.querySelector("[data-quota-label]").textContent = quota
    // A referência visual distribui a carga entre quatro catracas.
    row.querySelector("[data-load]").textContent = (quota / 4).toFixed(1)
    row.querySelector('button[data-action="fastpass-quotas#decrease"]').disabled = quota === 0
  }

  updateTotal() {
    this.totalTarget.textContent = this.rowTargets.reduce((sum, row) =>
      sum + Number(row.querySelector("[data-quota-value]").value), 0)
  }
}
