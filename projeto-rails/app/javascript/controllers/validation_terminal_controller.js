import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["clock", "mode", "simulation", "readButton", "identification", "records", "readerStatus", "banner", "resultTitle", "resultDetail", "student", "registration", "financial", "balance", "window", "readTime", "timeResult", "confirm"]
  static values = { okUrl: String, outsideUrl: String, balanceUrl: String, normalUrl: String, confirmUrl: String }

  connect() {
    this.selectedMode = "normal"
    this.currentResult = null
    this.busy = false
    this.abortController = new AbortController()
    this.updateClock()
    this.timer = setInterval(() => this.updateClock(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
    this.abortController.abort()
  }

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
    if (this.busy) return
    this.setMode(event.currentTarget.dataset.mode)
    this.clearReading()
  }

  clearReading() {
    if (this.busy) return
    this.currentResult = null
    this.confirmTarget.disabled = true
    this.bannerTarget.className = "terminal-result-banner"
    this.resultTitleTarget.textContent = "Aguardando identificação"
    this.resultDetailTarget.textContent = "Informe uma matrícula ou selecione um cenário para a busca automática."
    this.readerStatusTarget.textContent = "● Aguardando identificação"
    this.studentTarget.textContent = "—"
    this.registrationTarget.textContent = "Nenhuma leitura realizada"
    this.financialTarget.textContent = "Aguardando passagem"
    this.balanceTarget.textContent = "O saldo será consultado no cadastro do estudante."
    this.windowTarget.textContent = "—"
    this.readTimeTarget.textContent = "—"
    this.timeResultTarget.textContent = "Aguardando"
  }

  readIdentification() {
    return this.identificationTarget.value.trim()
  }

  processReading(event) {
    event.preventDefault()
    return this.sendReading(event.currentTarget.action)
  }

  simulate(event) {
    const scenario = event.currentTarget.dataset.scenario
    const urls = { ok: this.okUrlValue, outside: this.outsideUrlValue, balance: this.balanceUrlValue, normal: this.normalUrlValue }
    return this.sendReading(urls[scenario])
  }

  async sendReading(url) {
    if (this.busy) return
    this.clearReading()
    this.setBusy(true)
    try {
      const data = await this.post(url, { modo: this.selectedMode, matricula: this.readIdentification() })
      if (data) this.showResult(data)
    } catch (error) {
      this.showError(error)
    } finally {
      this.setBusy(false)
    }
  }

  async confirmPassage() {
    if (this.busy || !this.currentResult?.autorizacao) return
    this.setBusy(true)
    try {
      const data = await this.post(this.confirmUrlValue, { autorizacao: this.currentResult.autorizacao })
      if (data) this.showResult(data)
    } catch (error) {
      this.currentResult = null
      this.showError(error)
    } finally {
      this.setBusy(false)
    }
  }

  async post(url, body) {
    const response = await fetch(url, {
      method: "POST",
      credentials: "same-origin",
      signal: this.abortController.signal,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(body)
    })
    if (response.redirected) {
      window.location.assign(response.url)
      return null
    }
    const data = await response.json()
    if (!response.ok) throw new Error(data.erro || "Não foi possível concluir a operação.")
    return data
  }

  showResult(data) {
    this.currentResult = data
    this.setMode(data.modo)
    const blocked = !data.autorizado
    this.bannerTarget.className = `terminal-result-banner ${blocked ? "is-blocked" : "is-approved"}`
    this.resultTitleTarget.textContent = data.confirmado ? "PASSAGEM CONFIRMADA · SIMULAÇÃO" : blocked ? "ACESSO BLOQUEADO · SIMULAÇÃO" : "ACESSO LIBERADO · SIMULAÇÃO"
    const detalhes = {
      autorizado: "Leitura registrada. Aguardando confirmação da passagem.",
      fora_da_janela: "Leitura fora da janela sorteada. Tentativa bloqueada e registrada.",
      saldo_insuficiente: "Saldo insuficiente. Tentativa bloqueada e registrada.",
      sem_fastpass: "Estudante sem FastPass válido para esta data e turno. Tentativa bloqueada e registrada."
    }
    this.resultDetailTarget.textContent = data.confirmado ? "Passagem registrada e saldo do estudante atualizado." : detalhes[data.motivo] || "Leitura registrada."
    this.studentTarget.textContent = data.estudante.nome
    const origem = data.origem_leitura === "automatica" ? "Seleção automática" : data.origem_leitura === "informada" ? "Leitura informada" : "Identificação registrada"
    this.registrationTarget.textContent = `Matrícula: ${data.estudante.matricula} · ${origem}`
    this.financialTarget.textContent = data.confirmado ? `Débito realizado: ${this.money(data.valor_debitado)}` : "Nenhum débito realizado"
    this.balanceTarget.textContent = `Saldo: ${this.money(data.estudante.saldo)} · Tarifa: ${this.money(data.tarifa)}`
    this.windowTarget.textContent = data.janela || "Não se aplica"
    this.readTimeTarget.textContent = new Intl.DateTimeFormat("pt-BR", { timeZone: "America/Sao_Paulo", hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false }).format(new Date(data.horario))
    this.timeResultTarget.textContent = data.modo === "normal" ? "Modo comum" : !data.janela ? "Sem janela válida" : data.motivo === "fora_da_janela" ? "Fora da janela" : "Dentro da janela"
    this.readerStatusTarget.textContent = "● Leitura simulada registrada"
    this.recordsTarget.innerHTML = data.registros_html
  }

  money(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value)
  }

  setBusy(busy) {
    this.busy = busy
    this.element.setAttribute("aria-busy", String(busy))
    this.modeTargets.forEach(button => { button.disabled = busy })
    this.simulationTargets.forEach(button => { button.disabled = busy })
    this.readButtonTarget.disabled = busy
    this.identificationTarget.disabled = busy
    this.confirmTarget.disabled = busy || !this.currentResult?.autorizacao
  }

  showError(error) {
    if (error.name === "AbortError") return
    this.bannerTarget.className = "terminal-result-banner is-blocked"
    this.resultTitleTarget.textContent = "NÃO FOI POSSÍVEL CONCLUIR"
    this.resultDetailTarget.textContent = error.message || "Verifique a conexão e tente novamente."
  }
}
