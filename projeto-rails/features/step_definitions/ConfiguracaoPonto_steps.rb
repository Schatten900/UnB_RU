Dado("que o funcionario está autenticado") do
  @agora_ponto = Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 12, 0)
  allow(Time).to receive(:current).and_return(@agora_ponto)
  @turno_ponto = Turno.create!(nome: "Expediente", inicio: "09:00", fim: "17:00", preco: 0)
  @funcionario_ponto = Usuario.create!(
    matricula: "999149608",
    nome: "Funcionario de teste",
    senha: "senha-segura",
    perfil: "funcionario",
    turno: @turno_ponto,
    saldo: 0
  )

  visit login_path
  fill_in "matricula", with: @funcionario_ponto.matricula
  fill_in "senha", with: "senha-segura"
  click_button "Entrar no sistema"
end

Dado("que existem os seguintes restaurantes disponiveis:") do |tabela|
  @restaurantes_ponto = tabela.hashes.map do |linha|
    restaurante = Restaurante.create!(nome: "Restaurante #{linha.fetch('restaurante')}")
    restaurante.catracas.create!(piso: linha.fetch("andar").to_i, modo_acesso: "normal")
    restaurante
  end
end

Quando("o funcionário selecionar o restaurante {int}") do |numero|
  @restaurante_selecionado = @restaurantes_ponto.fetch(numero - 1)
  @catraca_selecionada = @restaurante_selecionado.catracas.first
  allow(Rails.logger).to receive(:info).and_call_original

  page.driver.post(
    operator_ponto_configuracao_path,
    restaurante_id: @restaurante_selecionado.id,
    catraca_id: @catraca_selecionada.id
  )
  visit operator_ponto_configuracao_path
end

Entao("o sistema deve configurar o restaurante {int} como ponto de gerenciamento") do |numero|
  expect(page).to have_text("Ponto de acesso configurado com sucesso")
  expect(page).to have_text("Restaurante #{numero}")
end

Entao("deve aplicar as regras correspondentes ao restaurante selecionado") do
  expect(@catraca_selecionada.restaurante_id).to eq(@restaurante_selecionado.id)
  expect(page).to have_text("Catraca ##{@catraca_selecionada.id}")
end

Entao("deve registrar os logs associados ao restaurante {int}") do |numero|
  mensagem = "Restaurante #{@restaurante_selecionado.id} e catraca #{@catraca_selecionada.id} selecionados por funcionário #{@funcionario_ponto.matricula}"
  expect(@restaurante_selecionado.nome).to eq("Restaurante #{numero}")
  expect(Rails.logger).to have_received(:info).with(mensagem)
end

Dado("que o funcionário não está autenticado") do
  page.driver.submit(:delete, logout_path, {})
end

Quando("ele tentar acessar a configuração do ponto de rede") do
  visit operator_ponto_configuracao_path
end

Entao("o sistema deve negar o acesso") do
  expect(page).to have_current_path(login_path)
  expect(page).to have_text("Acesso não autorizado")
end

Entao("não deve permitir a configuração do restaurante") do
  expect(page).to have_current_path(login_path)
  expect(page).not_to have_text("Ponto de acesso configurado com sucesso")
end

Entao("o sistema está indisponivel") do
  allow_any_instance_of(PontoConfiguracaoController)
    .to receive(:exigir_funcionario)
    .and_raise(ActiveRecord::ConnectionNotEstablished)
end

Entao("o sistema deve informar que o sistema está indisponivel") do
  visit operator_ponto_configuracao_path
  expect(page.status_code).to eq(503)
  expect(page).to have_text("O serviço está indisponível no momento")
end

Entao("não permitir a configuração do restaurante") do
  expect(page).to have_text("Nenhuma alteração foi salva")
end