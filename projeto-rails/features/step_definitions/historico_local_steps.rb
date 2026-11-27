Dado('que estou autenticado como funcionário') do
  entrar_aceitacao('999123456')
end

Dado('que estou gerenciando a catraca {string}') do |numero|
  catraca = catraca_aceitacao(numero)
  enviar_aceitacao(:post, operator_ponto_configuracao_path,
                   restaurante_id: catraca.restaurante_id, catraca_id: catraca.id)
end

Dado('que existem os seguintes registros de acesso:') do |tabela|
  tabela.hashes.each do |linha|
    liberado = linha.fetch('status') == 'Liberado'
    Acesso.create!(usuario: usuario_aceitacao(linha.fetch('matrícula')),
                   turno: turno_aceitacao, catraca: catraca_aceitacao(linha.fetch('catraca')),
                   data_hora: Time.current, status: liberado ? 'liberado' : 'bloqueado',
                   passagem_em: liberado ? Time.current : nil, valor_debitado: liberado ? 4.50 : 0)
  end
end

Quando('acesso o histórico local') do
  visit operator_historico_local_path
end

Então('devo visualizar os registros dos alunos {string} e {string}') do |primeiro, segundo|
  expect(page).to have_text(primeiro)
  expect(page).to have_text(segundo)
end

Então('devo visualizar seus respectivos status de acesso') do
  expect(page).to have_text('Liberado')
  expect(page).to have_text('Bloqueado')
end

Então('não devo visualizar o registro do aluno {string}') do |matricula|
  expect(page).not_to have_text(matricula)
end
