require "rails_helper"

RSpec.describe "Integração de inscrições e cotas FastPass", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  include ActiveJob::TestHelper

  let(:admin) { Usuario.create!(matricula: "999900001", nome: "Admin", senha: "senha") }
  let(:estudante) { Usuario.create!(matricula: "232040501", nome: "Estudante", senha: "senha", saldo: 20) }
  let(:outro) { Usuario.create!(matricula: "231045229", nome: "Outro", senha: "senha", saldo: 20) }
  let(:restaurante) { Restaurante.create!(nome: "RU") }
  let(:catraca) { restaurante.catracas.create!(piso: 1, modo_acesso: "fastpass") }
  let(:turno) { Turno.create!(nome: "Almoço", inicio: "11:00", fim: "14:00", preco: 4.5) }
  let(:janela) { turno.time_frames.create!(inicio: "12:00", fim: "12:15") }
  let(:sorteio) { Sorteio.create!(data: Date.current + 1, status: "aberto", cotas: { restaurante.id.to_s => { janela.id.to_s => 1 } }) }

  around { |exemplo| travel_to(Time.find_zone!("America/Sao_Paulo").local(2026, 11, 12, 10)) { exemplo.run } }

  def entrar(usuario)
    post login_path, params: { matricula: usuario.matricula, senha: "senha" }
  end

  def inscrever(usuario = estudante, **extras)
    entrar(usuario)
    post "/api/fast_passes", params: {
      sorteio_id: sorteio.id, time_frame_id: janela.id,
      restaurante_id: restaurante.id, catraca_id: catraca.id
    }.merge(extras), as: :json
  end

  def executar
    entrar(admin)
    post admin_sortear_fastpass_path, params: { sorteio_id: sorteio.id, restaurante_id: restaurante.id }
  end

  it "inscreve no sorteio escolhido sem contemplar, notificar ou debitar antecipadamente" do
    inscrever
    expect(response).to have_http_status(:created)
    inscricao = InscricaoFastpass.last
    expect(inscricao.sorteio_id).to eq(sorteio.id)
    expect(inscricao.catraca_id).to eq(catraca.id)
    expect(inscricao.resultado).to be_nil
    expect(inscricao.status_notificacao).to eq("pendente")
    expect(inscricao.notificada_em).to be_nil
    expect(estudante.reload.saldo).to eq(20)
    expect(Sorteio.count).to eq(1)
    expect(Acesso.count).to eq(0)
  end

  it "impede duplicidade no turno e ignora resultado e matrícula enviados pelo cliente" do
    inscrever(resultado: "ganhou", usuario_matricula: outro.matricula)
    expect(InscricaoFastpass.last.usuario_matricula).to eq(estudante.matricula)
    expect(InscricaoFastpass.last.resultado).to be_nil
    inscrever
    expect(response).to have_http_status(:unprocessable_content)
    expect(InscricaoFastpass.count).to eq(1)
  end

  it "rejeita sorteio inexistente, fechado, passado, janela sem cota e catraca de outro restaurante" do
    inscrever(sorteio_id: 0)
    expect(response).to have_http_status(:unprocessable_content)
    inscrever(sorteio_id: nil)
    expect(response).to have_http_status(:unprocessable_content)
    sorteio.update!(status: "concluido")
    inscrever
    expect(response).to have_http_status(:unprocessable_content)
    sorteio.update!(status: "aberto", data: Date.current - 1)
    inscrever
    expect(response).to have_http_status(:unprocessable_content)
    sorteio.update!(data: Date.current, cotas: {})
    inscrever
    expect(response).to have_http_status(:unprocessable_content)
    sorteio.update!(cotas: { restaurante.id.to_s => { janela.id.to_s => 1 } })
    outra = Restaurante.create!(nome: "Outro RU").catracas.create!(piso: 1, modo_acesso: "fastpass")
    inscrever(catraca_id: outra.id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(InscricaoFastpass.count).to eq(0)
  end

  it "sorteia até a cota, publica vencedores e perdedores e notifica uma única vez" do
    inscrever
    inscrever(outro)
    expect { executar }.to have_enqueued_job(NotificarFastPassJob).with(sorteio.id)
    expect(sorteio.reload.status).to eq("concluido")
    expect(InscricaoFastpass.group(:resultado).count).to eq("ganhou" => 1, "nao_ganhou" => 1)
    expect(InscricaoFastpass.pluck(:status_notificacao).uniq).to eq(["pendente"])
    NotificarFastPassJob.perform_now(sorteio.id)
    NotificarFastPassJob.perform_now(sorteio.id)
    expect(Notificacao.count).to eq(2)
    expect(InscricaoFastpass.pluck(:status_notificacao).uniq).to eq(["entregue"])
    expect(estudante.reload.saldo).to eq(20)
    resultados = InscricaoFastpass.order(:id).pluck(:resultado)
    executar
    expect(flash[:alert]).to be_present
    expect(InscricaoFastpass.order(:id).pluck(:resultado)).to eq(resultados)
    inscrever(Usuario.create!(matricula: "221012345", nome: "Terceiro", senha: "senha"))
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "limita as vagas por restaurante, somando inscritos de catracas diferentes" do
    inscrever
    segunda = restaurante.catracas.create!(piso: 2, modo_acesso: "fastpass")
    inscrever(outro, catraca_id: segunda.id)
    executar
    expect(InscricaoFastpass.where(resultado: "ganhou").count).to eq(1)
  end

  it "não repete o resultado ao reconfigurar cotas depois de concluído" do
    inscrever
    executar
    post admin_vagas_fastpass_path, params: {
      restaurante_id: restaurante.id, data: sorteio.data.to_s,
      cota_diaria: 2, cotas: { janela.id.to_s => 2 }
    }
    expect(flash[:alert]).to include("abertos")
    expect(sorteio.reload.cotas_do_restaurante(restaurante).values.sum).to eq(1)
  end

  it "separa cotas por restaurante e janela e não contempla janelas cuja cota foi zerada" do
    inscrever
    inscrever(outro)
    outro_ru = Restaurante.create!(nome: "RU 2")
    outra_catraca = outro_ru.catracas.create!(piso: 1, modo_acesso: "fastpass")
    outra_janela = turno.time_frames.create!(inicio: "12:15", fim: "12:30")
    terceiro = Usuario.create!(matricula: "221012345", nome: "Terceiro", senha: "senha")
    quarto = Usuario.create!(matricula: "221012346", nome: "Quarto", senha: "senha")
    quinto = Usuario.create!(matricula: "221012347", nome: "Quinto", senha: "senha")
    sorteio.update!(cotas: {
      restaurante.id.to_s => { janela.id.to_s => 1, outra_janela.id.to_s => 1 },
      outro_ru.id.to_s => { janela.id.to_s => 2 }
    })
    inscrever(terceiro, restaurante_id: outro_ru.id, catraca_id: outra_catraca.id)
    inscrever(quarto, restaurante_id: outro_ru.id, catraca_id: outra_catraca.id)
    inscrever(quinto, time_frame_id: outra_janela.id)
    sorteio.reload.update!(cotas: sorteio.cotas.deep_merge(restaurante.id.to_s => { outra_janela.id.to_s => 0 }))
    executar
    vencedores = InscricaoFastpass.where(resultado: "ganhou")
    expect(vencedores.where(catraca: catraca, time_frame: janela).count).to eq(1)
    expect(vencedores.where(catraca: outra_catraca).count).to eq(2)
    expect(InscricaoFastpass.find_by!(usuario: quinto).resultado).to eq("nao_ganhou")
  end

  it "autoriza o vencedor na catraca atribuída e só debita ao confirmar a passagem" do
    inscrever
    executar
    admin.update!(turno: turno)
    travel_to(Time.find_zone!("America/Sao_Paulo").local(2026, 11, 13, 12, 5))
    entrar(admin)
    post operator_ponto_configuracao_path, params: { restaurante_id: restaurante.id, catraca_id: catraca.id }
    post operator_processar_leitura_path, params: { matricula: estudante.matricula, modo: "fastpass" }, as: :json
    expect(response.parsed_body["autorizado"]).to be(true)
    expect(estudante.reload.saldo).to eq(20)
    autorizacao = response.parsed_body.fetch("autorizacao")
    post operator_confirmar_passagem_path, params: { autorizacao: autorizacao }, as: :json
    expect(response).to have_http_status(:ok)
    expect(estudante.reload.saldo).to eq(15.5)
    expect(estudante.historico_refeicoes.count).to eq(1)
    post operator_processar_leitura_path, params: { matricula: estudante.matricula, modo: "fastpass" }, as: :json
    expect(response.parsed_body["autorizado"]).to be(false)
    expect(response.parsed_body["motivo"]).to eq("fastpass_utilizado")
    expect(estudante.reload.saldo).to eq(15.5)
  end

  it "não usa a configuração antiga quando uma janela foi removida" do
    sorteio
    janela.destroy!
    executar
    expect(flash[:alert]).to include("Revise")
    expect(sorteio.reload.status).to eq("aberto")
  end

  it "aceita menos participantes que vagas e rejeita janela com cota zero" do
    sorteio.update!(cotas: { restaurante.id.to_s => { janela.id.to_s => 3 } })
    inscrever
    executar
    expect(InscricaoFastpass.where(resultado: "ganhou").count).to eq(1)
    sorteio.update!(status: "aberto", data: Date.current, cotas: { restaurante.id.to_s => { janela.id.to_s => 0 } })
    inscrever(outro)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "mostra o sorteio selecionado e o estado real da inscrição na tela do estudante" do
    inscrever
    get student_fast_pass_path, params: { sorteio_id: sorteio.id, restaurante_id: restaurante.id }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Aguardando sorteio", sorteio.data.strftime("%d/%m/%Y"))
    expect(response.body).not_to include("884-D", "Válido em 42 min")
  end

  it "exige estudante para inscrição e administrador para execução" do
    post "/api/fast_passes", as: :json
    expect(response).to have_http_status(:unauthorized)
    entrar(admin)
    post "/api/fast_passes", as: :json
    expect(response).to have_http_status(:forbidden)
    entrar(estudante)
    post admin_sortear_fastpass_path, params: { sorteio_id: sorteio.id }
    expect(response).to redirect_to(login_path)
    expect(sorteio.reload.status).to eq("aberto")
  end

  it "inscreve pelo formulário web usando o mesmo serviço da API" do
    sorteio
    entrar(estudante)
    post student_fast_pass_path, params: {
      sorteio_id: sorteio.id, restaurante_id: restaurante.id,
      time_frame_id: janela.id, catraca_id: catraca.id
    }
    expect(response).to redirect_to(student_fast_pass_path(sorteio_id: sorteio.id, restaurante_id: restaurante.id))
    follow_redirect!
    expect(response.body).to include("Aguardando sorteio")
    expect(InscricaoFastpass.last.resultado).to be_nil
  end

  it "não cria sorteios ao apenas visitar a tela do estudante" do
    entrar(estudante)
    expect { get student_fast_pass_path }.not_to change(Sorteio, :count)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nenhum sorteio disponível")
  end
end
