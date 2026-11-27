require 'active_support/testing/time_helpers'
require 'rspec/expectations'

module OperacaoRu
  def turno_aceitacao
    @turno_aceitacao ||= Turno.create!(nome: 'Almoço', inicio: '11:00', fim: '14:00', preco: 4.50)
  end

  def usuario_aceitacao(matricula, saldo: 0)
    Usuario.find_by(matricula: matricula) || Usuario.create!(
      matricula: matricula, nome: "Usuário #{matricula}", senha: 'senha-aceitacao',
      saldo: saldo, turno: turno_aceitacao
    )
  end

  def entrar_aceitacao(matricula)
    @usuario_aceitacao = usuario_aceitacao(matricula)
    visit login_path
    fill_in 'matricula', with: matricula
    fill_in 'senha', with: 'senha-aceitacao'
    click_button 'Entrar no sistema'
  end

  def restaurante_aceitacao
    @restaurante_aceitacao ||= Restaurante.create!(nome: 'RU de aceitação')
  end

  def catraca_aceitacao(numero, modo: 'normal')
    Catraca.find_by(id: numero.to_i) || Catraca.create!(
      id: numero.to_i, restaurante: restaurante_aceitacao, piso: 1, modo_acesso: modo
    )
  end

  def enviar_aceitacao(metodo, rota, dados = {})
    page.driver.submit(metodo, rota, dados)
  end

  def texto_pdf_aceitacao
    @pdf_aceitacao.scan(/<([0-9a-f]+)>/i).flatten.map do |hexadecimal|
      [hexadecimal].pack('H*').force_encoding('Windows-1252').encode('UTF-8', undef: :replace)
    end.join
  end
end

World(OperacaoRu, ActiveSupport::Testing::TimeHelpers, RSpec::Matchers)

Before do |cenario|
  arquivos = %w[local_access_history.feature restaurant_management.feature student_history_pdf.feature
                fastpass_validation.feature]
  if arquivos.include?(File.basename(cenario.location.file))
    @agora_aceitacao = Time.find_zone!('America/Sao_Paulo').local(2026, 5, 20, 12, 20)
    travel_to @agora_aceitacao
  end
end

After do
  travel_back if @agora_aceitacao
end
