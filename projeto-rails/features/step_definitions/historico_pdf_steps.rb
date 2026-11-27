Dado('que possuo {int} lançamentos em maio e {int} em abril') do |maio, abril|
  { 5 => maio, 4 => abril }.each do |mes, quantidade|
    quantidade.times do |indice|
      @usuario_aceitacao.recargas.create!(valor: mes == 4 ? 99 : indice + 1,
                                          metodo: 'pix', status: 'concluida',
                                          data_hora: Time.find_zone!('America/Sao_Paulo').local(2026, mes, indice + 1, 12))
    end
  end
end

Dado('que o histórico exibe {int} lançamentos por página') do |quantidade|
  @tamanho_pagina_aceitacao = quantidade
end

Dado('que não possuo lançamentos em abril') do
  expect(@usuario_aceitacao.recargas).to be_empty
end

Quando('filtro os lançamentos pelo mês de maio') do
  visit student_extrato_refeicoes_path(mes_referencia: '2026-05', por_pagina: @tamanho_pagina_aceitacao)
  expect(page).to have_css('.statement-table tbody tr', count: 5)
end

Quando('filtro os lançamentos pelo mês de abril') do
  visit student_extrato_refeicoes_path(mes_referencia: '2026-04')
end

Quando('solicito a exportação em PDF') do
  click_link 'Exportar PDF'
  @pdf_aceitacao = page.body.b
end

Então('devo receber um arquivo PDF') do
  expect(page.response_headers.fetch('Content-Type')).to include('application/pdf')
  expect(@pdf_aceitacao).to start_with('%PDF-')
end

Então('o arquivo deve conter os {int} lançamentos de maio') do |quantidade|
  expect(texto_pdf_aceitacao.scan('Recarga de Saldo').size).to eq(quantidade)
end

Então('não deve conter o lançamento de abril') do
  expect(texto_pdf_aceitacao).not_to include('99,00')
end

Então('o arquivo não deve conter lançamentos') do
  expect(texto_pdf_aceitacao).to include('Nenhum lançamento encontrado')
  expect(texto_pdf_aceitacao).not_to include('Recarga de Saldo')
end
