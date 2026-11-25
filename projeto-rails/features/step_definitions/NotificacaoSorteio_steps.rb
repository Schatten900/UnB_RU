Dado("que existe um sorteio de FastPass") do
  @agora_sorteio = Time.find_zone!("America/Sao_Paulo").local(2026, 10, 30, 11, 0)
  allow(Time).to receive(:current).and_return(@agora_sorteio)
  @sorteio = Sorteio.create!(data: @agora_sorteio.to_date, status: "concluido")
  @turno_sorteio = Turno.create!(nome: "Almoco", inicio: "12:00", fim: "14:00", preco: 4.50)
  @time_frame_sorteio = TimeFrame.create!(turno: @turno_sorteio, inicio: "12:00", fim: "12:30")
  @inscricoes_sorteio = {}
end

Dado("que os seguintes estudantes participaram do sorteio:") do |tabela|
  tabela.hashes.each do |linha|
    resultado = if linha.fetch("resultado").downcase == "ganhou"
                  InscricaoFastpass::RESULTADO_GANHOU
                else
                  InscricaoFastpass::RESULTADO_NAO_GANHOU
                end
    matricula = linha.fetch("matrícula")
    estudante = Usuario.create!(
      matricula: matricula,
      nome: "Estudante #{matricula}",
      senha: "senha-segura",
      perfil: "estudante",
      saldo: 0
    )
    @inscricoes_sorteio[matricula] = InscricaoFastpass.create!(
      usuario: estudante,
      sorteio: @sorteio,
      time_frame: @time_frame_sorteio,
      resultado: resultado,
      status_notificacao: "pendente"
    )
  end
end

Dado('que o estudante "{int}" ganhou o FastPass') do |matricula|
  @inscricao_notificada = @inscricoes_sorteio.fetch(matricula.to_s)
  expect(@inscricao_notificada.resultado).to eq(InscricaoFastpass::RESULTADO_GANHOU)
end

Dado('que o estudante "{int}" não ganhou o FastPass') do |matricula|
  @inscricao_notificada = @inscricoes_sorteio.fetch(matricula.to_s)
  expect(@inscricao_notificada.resultado).to eq(InscricaoFastpass::RESULTADO_NAO_GANHOU)
end

Dado('que o estudante "{int}" ganhou o sorteio de FastPass') do |matricula|
  @inscricao_notificada = @inscricoes_sorteio.fetch(matricula.to_s)
  expect(@inscricao_notificada.resultado).to eq(InscricaoFastpass::RESULTADO_GANHOU)
end

Dado("que falta uma hora para o turno desse estudante") do
  expect(@agora_sorteio + 1.hour).to eq(@agora_sorteio.beginning_of_day + 12.hours)
end

Quando("chegar o horário de envio das notificações") do
  NotificarFastPassJob.perform_now
end

Então("o sistema deve enviar uma notificação informando que ele ganhou o FastPass") do
  mensagens = Notificacao.where(usuario_matricula: @inscricao_notificada.usuario_matricula).pluck(:mensagem)
  expect(mensagens).to include("Parabéns! Você ganhou o FastPass.")
  expect(@inscricao_notificada.reload.status_notificacao).to eq("entregue")
end

Então("o sistema deve enviar uma notificação informando que ele não ganhou o FastPass") do
  mensagens = Notificacao.where(usuario_matricula: @inscricao_notificada.usuario_matricula).pluck(:mensagem)
  expect(mensagens).to include("Você não foi contemplado no sorteio de FastPass.")
  expect(@inscricao_notificada.reload.status_notificacao).to eq("entregue")
end

Então("que o serviço de notificação está indisponivel") do
  allow(NotificacaoService).to receive(:call).and_raise(StandardError, "servico indisponivel")
end

Então("o sistema não deve confirmar o envio da notificação") do
  NotificarFastPassJob.perform_now
  expect(Notificacao.where(usuario_matricula: @inscricao_notificada.usuario_matricula)).to be_empty
end

Então("deve tratar a falha de envio conforme a regra definida pelo sistema") do
  expect(@inscricao_notificada.reload.status_notificacao).to eq("falhou")
end