require "rails_helper"

RSpec.describe "Exportação do histórico do estudante", type: :request do
  let(:estudante) { Usuario.create!(matricula: "221012345", nome: "Estudante", senha: "senha", saldo: 20) }
  let(:rota) { student_exportar_historico_path }

  def entrar(usuario = estudante)
    post login_path, params: { matricula: usuario.matricula, senha: "senha" }
  end

  it "exige autenticação" do
    get rota
    expect(response).to redirect_to(login_path)
  end

  it "impede exportação por administrador" do
    entrar(Usuario.create!(matricula: "999912345", nome: "Admin", senha: "senha", saldo: 0))
    get rota
    expect(response).to have_http_status(:forbidden)
  end

  it "exporta todas as páginas e ignora a matrícula informada pelo cliente" do
    outro = Usuario.create!(matricula: "231045229", nome: "Outro", senha: "senha", saldo: 0)
    6.times do |i|
      estudante.recargas.create!(valor: i + 1, metodo: "pix", status: "concluida", data_hora: "2026-05-02 12:00")
    end
    outro.recargas.create!(valor: 99, metodo: "pix", status: "concluida", data_hora: "2026-05-02 12:00")
    entrar
    filtros = { mes_referencia: "2026-05", evento: "recarga", metodo: "pix", pagina: 2, por_pagina: 5 }
    get student_extrato_refeicoes_path, params: filtros
    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.css(".statement-table tbody tr").size).to eq(1)
    link = html.at_css('a[href*="extrato_refeicoes/exportar"]')["href"]
    expect(link).to include("mes_referencia=2026-05", "evento=recarga", "metodo=pix")
    expect(link).not_to include("pagina=")

    allow(GeradorHistoricoPdf).to receive(:call).and_call_original
    get rota, params: filtros.merge(usuario_matricula: outro.matricula)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("attachment", "historico_221012345.pdf")
    expect(response.body).to start_with("%PDF-")
    expect(GeradorHistoricoPdf).to have_received(:call) do |usuario:, lancamentos:|
      expect(usuario).to eq(estudante)
      expect(lancamentos.size).to eq(6)
      expect(lancamentos.sum { |item| item[:valor] }).to eq(21)
    end
  end

  it "exporta histórico vazio e rejeita mês inválido sem erro interno" do
    entrar
    get rota, params: { mes_referencia: "2026-04" }
    expect(response.media_type).to eq("application/pdf")
    get rota, params: { mes_referencia: "2026-13" }
    expect(response).to have_http_status(:bad_request)
    get student_extrato_refeicoes_path, params: { mes_referencia: "invalido" }
    expect(response).to have_http_status(:bad_request)
  end
end
