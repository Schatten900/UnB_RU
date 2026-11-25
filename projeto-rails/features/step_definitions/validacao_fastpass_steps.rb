Dado(/^que a refeição custa R\$ (\d+,\d{2})$/) do |preco|
  turno_aceitacao.update!(preco: preco.tr(",", ".").to_d)
  entrar_aceitacao("999123456")
end

Dado(/^que o aluno "([^"]+)" possui saldo de R\$ (\d+,\d{2})$/) do |matricula, saldo|
  usuario_aceitacao(matricula).update!(saldo: saldo.tr(",", ".").to_d)
end

Dado("que o aluno {string} não possui FastPass") do |matricula|
  expect(InscricaoFastpass.where(usuario_matricula: matricula)).to be_empty
end

Dado("que o aluno {string} ganhou um FastPass das {int}:{int} às {int}:{int}") do |matricula, hi, mi, hf, mf|
  sorteio = Sorteio.find_or_create_by!(data: Time.current.to_date) { |novo| novo.status = "concluido" }
  janela = TimeFrame.find_or_create_by!(turno: turno_aceitacao, inicio: format("%02d:%02d", hi, mi), fim: format("%02d:%02d", hf, mf))
  InscricaoFastpass.create!(usuario: usuario_aceitacao(matricula), sorteio: sorteio,
    time_frame: janela, catraca: catraca_aceitacao("04", modo: "fastpass"), resultado: "ganhou")
end

Dado("que a catraca está no modo exclusivo FastPass") do
  catraca = catraca_aceitacao("04", modo: "fastpass")
  enviar_aceitacao(:post, operator_ponto_configuracao_path,
                   restaurante_id: catraca.restaurante_id, catraca_id: catraca.id)
end

Quando("o aluno {string} apresenta seu QR Code às {int}:{int}") do |matricula, horas, minutos|
  travel_to @agora_aceitacao.change(hour: horas, min: minutos)
  @matricula_lida = matricula
  enviar_aceitacao(:post, "/api/fastpass/validacoes", matricula: matricula)
  @validacao_aceitacao = JSON.parse(page.body)
end

Quando("o aluno {string} apresenta seu QR Code") do |matricula|
  @matricula_lida = matricula
  enviar_aceitacao(:post, "/api/fastpass/validacoes", matricula: matricula)
  @validacao_aceitacao = JSON.parse(page.body)
end

Então("a catraca deve liberar sua entrada") do
  expect(page.status_code).to eq(201)
  expect(@validacao_aceitacao).to include("autorizado" => true, "status" => "pendente")
end

Então("a entrada deve ser bloqueada") do
  expect(page.status_code).to eq(422)
  expect(@validacao_aceitacao).to include("autorizado" => false, "status" => "bloqueado")
end

Então(/^seu saldo deve permanecer em R\$ (\d+,\d{2})$/) do |saldo|
  expect(Usuario.find(@matricula_lida).saldo).to eq(saldo.tr(",", ".").to_d)
end

Quando("a passagem pela catraca é confirmada") do
  enviar_aceitacao(:post, "/api/fastpass/acessos/#{@validacao_aceitacao.fetch('acesso_id')}/confirmar")
  expect(page.status_code).to eq(200)
end

Então(/^seu saldo deve ser reduzido para R\$ (\d+,\d{2})$/) do |saldo|
  expect(Usuario.find(@matricula_lida).saldo).to eq(saldo.tr(",", ".").to_d)
  expect(Acesso.find(@validacao_aceitacao.fetch("acesso_id")).passagem_em).to be_present
end
