Dado('que existe um cardapio para a refeicao atual') do
  @agora_cardapio = Time.find_zone!('America/Sao_Paulo').local(2026, 10, 30, 12, 0)
  allow(Time).to receive(:current).and_return(@agora_cardapio)
  @turno_cardapio = Turno.create!(nome: 'Almoco', inicio: '11:00', fim: '14:00', preco: 4.50)
  @estudante_cardapio = Usuario.create!(
    matricula: '232040501',
    nome: 'Estudante de teste',
    senha: 'senha-segura',
    perfil: 'estudante',
    saldo: 10
  )
end

Dado('que o cardápio contém as seguintes opções:') do |tabela|
  atributos = tabela.hashes.each_with_object({}) do |linha, resultado|
    campo = case linha.fetch('tipo de alimento').downcase
            when 'padrão'
              :opcao_padrao
            when 'ovolactovegetariano'
              :opcao_ovolactovegetariana
            when 'vegetariano estrito'
              :opcao_vegetariana_estrita
            else
              raise ArgumentError, "Tipo de alimento desconhecido: #{linha.fetch('tipo de alimento')}"
            end
    resultado[campo] = linha.fetch('proteina')
  end

  Cardapio.create!(turno: @turno_cardapio, data: @agora_cardapio.to_date, **atributos)
end

Dado('que não existe um cardápio para a refeição atual') do
  @agora_cardapio = Time.find_zone!('America/Sao_Paulo').local(2026, 10, 30, 12, 0)
  allow(Time).to receive(:current).and_return(@agora_cardapio)
  @turno_cardapio = Turno.create!(nome: 'Almoco', inicio: '11:00', fim: '14:00', preco: 4.50)
  @estudante_cardapio = Usuario.create!(
    matricula: '232040501',
    nome: 'Estudante de teste',
    senha: 'senha-segura',
    perfil: 'estudante',
    saldo: 10
  )
end

Quando('o estudante acessar o cardapio da refeição atual') do
  visit login_path
  fill_in 'matricula', with: @estudante_cardapio.matricula
  fill_in 'senha', with: 'senha-segura'
  click_button 'Entrar no sistema'
end

Entao('o sistema deve informar as opções da refeição atual') do
  expect(page).to have_text('Filé de Frango')
  expect(page).to have_text('Suflê de chuchu')
  expect(page).to have_text('Quinoa com legumes refogados')
end

Entao('o sistema deve informa que o cardapio não esta disponivel') do
  expect(page).to have_text('Não há cardápio disponível agora')
end
