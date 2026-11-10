module ExtratoRefeicoesHelper
  def moeda_extrato(valor)
    number_to_currency(valor, unit: "R$ ", separator: ",", delimiter: ".")
  end

  def pagina_extrato(numero)
    student_extrato_refeicoes_path(request.query_parameters.merge("pagina" => numero))
  end
end
