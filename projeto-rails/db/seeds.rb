if Rails.env.development?

turno2 = Turno.find_or_initialize_by(nome: "Tarde - refeição atual")
turno2.update!(inicio: "14:00", fim: "17:00", preco: 4.50)

turno = Turno.find_or_initialize_by(nome: "Demo - refeição atual")
turno.update!(inicio: "17:00", fim: "23:00", preco: 4.50)

restaurantes = ["Demo - RU Darcy Ribeiro", "Demo - RU Gama"].map do |nome|
	Restaurante.find_or_create_by!(nome: nome)
end

restaurantes.each_with_index do |restaurante, index|
	catraca = Catraca.find_or_initialize_by(restaurante_id: restaurante.id, piso: index + 1)
	catraca.update!(modo_acesso: "normal")
end

estudante = Usuario.find_or_initialize_by(matricula: "232040501")
estudante.assign_attributes(
	nome: "Estudante de demonstração",
	perfil: "estudante",
	turno: turno,
	restaurante: restaurantes.second,
	saldo: 4.5
)
estudante.senha = "Demo1234!"
estudante.save!


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


funcionario2 = Usuario.find_or_initialize_by(matricula: "999000002")
funcionario2.assign_attributes(
	nome: "Funcionário de demonstração 2",
	perfil: "funcionario",
	turno: turno2,
	restaurante: restaurantes.first,
	saldo: 0
)
funcionario2.senha = "Demo1234!"
funcionario2.save!


cardapio = Cardapio.find_or_initialize_by(turno: turno, data: Date.current)
cardapio.update!(
	opcao_padrao: "Frango Assado",
	opcao_ovolactovegetariana: "Omelete de legumes",
	opcao_vegetariana_estrita: "Quinoa com legumes refogados"
)

cardapio_tarde = Cardapio.find_or_initialize_by(turno: turno2, data: Date.current)
cardapio_tarde.update!(
	opcao_padrao: "Lasanha de frango",
	opcao_ovolactovegetariana: "Moqueca de banana com proteína de soja",
	opcao_vegetariana_estrita: "Lasanha de brócolis"
)

puts "Dados de demonstração carregados."
puts "Login funcionário: 999000001 / Demo1234!"

puts "Login funcionário 2: 999000002 / Demo1234!"

puts "Restaurantes: #{restaurantes.map(&:nome).join(', ')}"
puts "Cardápios de hoje: tarde, das 14:00 às 16:00; demo, das 17:00 às 23:00."
puts "Dados de demonstração carregados."
puts "Login estudante: 232040501 / Demo1234!"
puts "Restaurantes: #{restaurantes.map(&:nome).join(', ')}"
puts "Cardápios de hoje: tarde, das 14:00 às 16:00; demo, das 17:00 às 23:00."

end
