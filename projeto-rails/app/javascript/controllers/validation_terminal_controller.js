import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["clock", "mode", "readerStatus", "banner", "resultTitle", "resultDetail", "student", "registration", "financial", "balance", "window", "readTime", "timeResult", "confirm"]

  connect() {
    this.selectedMode = "normal"
    this.updateClock()
    this.timer = setInterval(() => this.updateClock(), 1000)
  }

  disconnect() { clearInterval(this.timer) }

  time() {
    return new Intl.DateTimeFormat("pt-BR", { timeZone: "America/Sao_Paulo", hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false }).format(new Date())
  }

  updateClock() { this.clockTarget.textContent = this.time() }

  setMode(mode) {
    this.selectedMode = mode
    this.modeTargets.forEach(button => {
      const active = button.dataset.mode === mode
      button.classList.toggle("is-selected", active)
      button.setAttribute("aria-pressed", String(active))
    })
  }

  changeMode(event) {
    this.setMode(event.currentTarget.dataset.mode)
    this.confirmTarget.disabled = true
    this.bannerTarget.className = "terminal-result-banner"
    this.resultTitleTarget.textContent = "Modo de simulação alterado"
    this.resultDetailTarget.textContent = "Selecione uma nova leitura para continuar."
  }

  simulate(event) {
    const scenario = event.currentTarget.dataset.scenario
    if (scenario === "normal") this.setMode("normal")
    if (scenario === "outside") this.setMode("fastpass")
    const blocked = scenario === "outside" || scenario === "balance"
    const fastpass = this.selectedMode === "fastpass"
    this.bannerTarget.className = `terminal-result-banner ${blocked ? "is-blocked" : "is-approved"}`
    this.resultTitleTarget.textContent = blocked ? "ACESSO BLOQUEADO · SIMULAÇÃO" : "ACESSO LIBERADO · SIMULAÇÃO"
    this.resultDetailTarget.textContent = scenario === "outside" ? "Leitura fora da janela sorteada." : scenario === "balance" ? "Saldo insuficiente para a refeição." : "Autorização simulada. Aguardando confirmação da passagem."
    this.studentTarget.textContent = "Mariana Souza Silva (exemplo)"
    this.registrationTarget.textContent = "Matrícula: 221045999 · Dados fictícios"
    this.financialTarget.textContent = "Nenhum débito realizado"
    this.balanceTarget.textContent = scenario === "balance" ? "Saldo de exemplo: R$ 0,00" : "Saldo de exemplo: R$ 18,00 · Tarifa simulada: R$ 4,50"
    this.windowTarget.textContent = fastpass ? (scenario === "outside" ? "Janela de exemplo encerrada" : "Janela de exemplo válida") : "Não se aplica"
    this.readTimeTarget.textContent = this.time()
    this.timeResultTarget.textContent = fastpass ? (scenario === "outside" ? "Fora da janela" : "Dentro da janela") : "Modo comum"
    this.readerStatusTarget.textContent = "● Leitura simulada recebida"
    this.confirmTarget.disabled = blocked
  }

  confirmPassage() {
    this.confirmTarget.disabled = true
    this.resultTitleTarget.textContent = "PASSAGEM CONFIRMADA · SIMULAÇÃO"
    this.resultDetailTarget.textContent = "Demonstração concluída. Nenhum registro foi salvo no banco."
    this.financialTarget.textContent = "Débito simulado: R$ 4,50"
    this.balanceTarget.textContent = "Saldo de exemplo após passagem: R$ 13,50"
  }
}
