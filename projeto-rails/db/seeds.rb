abort "Os dados de demonstração só podem ser carregados em desenvolvimento." unless Rails.env.development?

turno = Turno.find_or_initialize_by(nome: "Demo - refeição atual")
turno.update!(inicio: "17:00", fim: "20:00", preco: 4.50)

restaurantes = ["Demo - RU Darcy Ribeiro", "Demo - RU Gama"].map do |nome|
	Restaurante.find_or_create_by!(nome: nome)
end

restaurantes.each_with_index do |restaurante, index|
	catraca = Catraca.find_or_initialize_by(restaurante_id: restaurante.id, piso: index + 1)
	catraca.update!(modo_acesso: "normal")
end

funcionario = Usuario.find_or_initialize_by(matricula: "999000001")
funcionario.assign_attributes(
	nome: "Funcionário de demonstração",
	perfil: "funcionario",
	turno: turno,
	restaurante: restaurantes.first,
	saldo: 0
)
funcionario.senha = "Demo1234!"
funcionario.save!

cardapio = Cardapio.find_or_initialize_by(turno: turno, data: Date.current)
cardapio.update!(
	opcao_padrao: "Frango grelhado com arroz e feijão",
	opcao_ovolactovegetariana: "Omelete de legumes",
	opcao_vegetariana_estrita: "Quinoa com legumes refogados"
)

puts "Dados de demonstração carregados."
puts "Login funcionário: 999000001 / Demo1234!"
puts "Restaurantes: #{restaurantes.map(&:nome).join(', ')}"
puts "Cardápio disponível hoje, das 17:00 às 20:00."
