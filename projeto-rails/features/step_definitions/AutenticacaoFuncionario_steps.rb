Dado('que existem os seguintes funcionarios:') do |tabela|
  @turno_autenticacao = Turno.create!(nome: 'Expediente', inicio: '10:00', fim: '14:00', preco: 0)
  @funcionarios_autenticacao = tabela.hashes.each_with_object({}) do |linha, resultado|
    nome = linha.fetch('funcionario').downcase
    resultado[nome] = Usuario.create!(
      matricula: linha.fetch('matricula'),
      nome: nome.capitalize,
      senha: 'senha-segura',
      perfil: 'funcionario',
      turno: @turno_autenticacao,
      saldo: 0
    )
  end
end

Dado(/^que (José|Fernando|Maria) tentou fazer login às (\d{2}:\d{2})$/) do |nome, horario|
  horas, minutos = horario.split(':').map(&:to_i)
  @horario_login = Time.find_zone!('America/Sao_Paulo').local(2026, 10, 30, horas, minutos)
  allow(Time).to receive(:current).and_return(@horario_login)
  chave = nome.downcase.tr('é', 'e')
  @funcionario_login = @funcionarios_autenticacao.fetch(chave)
end

Quando(/^(?:ele informa suas credenciais válidas|ela solicita a autenticacao com credenciais válidas)$/) do
  visit login_path
  fill_in 'matricula', with: @funcionario_login.matricula
  fill_in 'senha', with: 'senha-segura'
  click_button 'Entrar no sistema'
end

Entao('o sistema deve autentificar sua sessão') do
  expect(page).to have_current_path(operator_ponto_configuracao_path)
end

Entao('permitir operar o sistema de forma segura') do
  expect(page).to have_text('Operador autenticado')
end

Entao('o sistema deverá negar a autenticação') do
  expect(page).to have_current_path(login_path)
  expect(page).to have_text('Não foi possível autenticar')
end

Entao('impedir o acesso ao sistema') do
  visit operator_ponto_configuracao_path
  expect(page).to have_current_path(login_path)
end

Dado('que o sistema está indisponivel') do
  allow(AutenticacaoFuncionarioService).to receive(:call)
    .and_raise(ActiveRecord::ConnectionNotEstablished)
end

Entao('o sistema não deve estabelecer uma sessão autenticada') do
  visit login_path
  fill_in 'matricula', with: @funcionario_login.matricula
  fill_in 'senha', with: 'senha-segura'
  click_button 'Entrar no sistema'
  @resposta_login = page.text
  visit operator_ponto_configuracao_path
  expect(page).to have_current_path(login_path)
end

Entao('deverá informar que o serviço está indisponivel') do
  expect(@resposta_login).to include('O serviço está indisponivel no momento')
end
