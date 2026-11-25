Dado("que estou autenticado como administrador") do
  entrar_aceitacao("999912345")
end

Dado("que estou autenticado como funcionário não administrador") do
  entrar_aceitacao("999123456")
end

Quando("cadastro o restaurante {string}") do |nome|
  enviar_aceitacao(:post, admin_restaurantes_path, restaurante: { nome: nome })
  @restaurante_gerenciado = Restaurante.find_by!(nome: nome)
end

Quando("cadastro a catraca {string} associada a esse restaurante") do |numero|
  (1...numero.to_i).each do |id|
    Catraca.create!(id: id, restaurante: @restaurante_gerenciado, piso: 1, modo_acesso: "normal")
  end
  enviar_aceitacao(:post, admin_catracas_path,
                   catraca: { restaurante_id: @restaurante_gerenciado.id, piso: 1, modo_acesso: "normal" })
  @catraca_gerenciada = Catraca.find(numero.to_i)
end

Então("o restaurante deve aparecer na lista de restaurantes") do
  visit admin_restaurantes_path
  expect(page).to have_text(@restaurante_gerenciado.nome)
end

Então("a catraca {string} deve aparecer associada a ele") do |numero|
  expect(@restaurante_gerenciado.catracas.find(numero.to_i)).to eq(@catraca_gerenciada)
  expect(page).to have_text("Catraca #{numero}")
end

Dado("que existe o restaurante {string} com a catraca {string}") do |nome, numero|
  @restaurante_gerenciado = Restaurante.create!(nome: nome)
  @catraca_gerenciada = Catraca.create!(id: numero.to_i, restaurante: @restaurante_gerenciado, piso: 1, modo_acesso: "normal")
end

Dado("que existe o restaurante {string} com a catraca {string} no piso {int}") do |nome, numero, piso|
  @restaurante_gerenciado = Restaurante.create!(nome: nome)
  @catraca_gerenciada = Catraca.create!(id: numero.to_i, restaurante: @restaurante_gerenciado, piso: piso, modo_acesso: "normal")
end

Quando("altero o nome do restaurante para {string}") do |nome|
  enviar_aceitacao(:patch, admin_restaurante_path(@restaurante_gerenciado), restaurante: { nome: nome })
  @nome_esperado = nome
end

Quando("altero o piso da catraca {string} para {int}") do |numero, piso|
  enviar_aceitacao(:patch, admin_catraca_path(numero.to_i), catraca: { piso: piso })
  @piso_esperado = piso
end

Então("as alterações devem ser salvas e exibidas") do
  visit admin_restaurantes_path
  expect(@restaurante_gerenciado.reload.nome).to eq(@nome_esperado)
  expect(@catraca_gerenciada.reload.piso).to eq(@piso_esperado)
  expect(page).to have_text(@nome_esperado)
  expect(page).to have_text("PISO #{@piso_esperado}")
end

Quando("removo a catraca {string}") do |numero|
  enviar_aceitacao(:delete, admin_catraca_path(numero.to_i))
end

Quando("removo o restaurante {string}") do |nome|
  enviar_aceitacao(:delete, admin_restaurante_path(Restaurante.find_by!(nome: nome)))
end

Então("ambos não devem mais aparecer na lista de cadastros") do
  visit admin_restaurantes_path
  expect(Restaurante.exists?(@restaurante_gerenciado.id)).to be(false)
  expect(Catraca.exists?(@catraca_gerenciada.id)).to be(false)
  expect(page).not_to have_text(@restaurante_gerenciado.nome)
end

Quando("tento cadastrar um novo restaurante") do
  enviar_aceitacao(:post, admin_restaurantes_path, restaurante: { nome: "RU não autorizado" })
end

Então("a operação deve ser negada") do
  expect(page).to have_current_path(operator_ponto_configuracao_path)
end

Então("o restaurante não deve ser cadastrado") do
  expect(Restaurante.exists?(nome: "RU não autorizado")).to be(false)
end
