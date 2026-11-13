module ExtratoRefeicoesHelper
  def moeda_extrato(valor)
    number_to_currency(valor, unit: "R$ ", separator: ",", delimiter: ".")
  end

  def pagina_extrato(numero)
    student_extrato_refeicoes_path(parametros_retorno_extrato.merge("pagina" => numero))
  end

  def parametros_retorno_extrato
    (@filtros || {}).merge("pagina" => @pagina, "por_pagina" => @por_pagina).compact
  end

  def recibo_extrato_path(lancamento)
    student_recibo_extrato_refeicoes_path(
      parametros_retorno_extrato.merge(tipo: lancamento[:tipo], id: lancamento[:registro_id])
    )
  end
end
