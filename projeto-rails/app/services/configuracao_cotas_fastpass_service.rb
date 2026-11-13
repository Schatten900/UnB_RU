class ConfiguracaoCotasFastpassService
  def self.call(restaurante:, data:, cota_diaria:, cotas:)
    data = Date.iso8601(data.to_s)
    raise ArgumentError, "Escolha uma data a partir de hoje." if data < Date.current
    total = inteiro(cota_diaria)
    janelas = TimeFrame.order(:id).pluck(:id).map(&:to_s)
    valores = cotas.to_h.stringify_keys.transform_values { |valor| inteiro(valor) }
    raise ArgumentError, "Informe a cota de todas as janelas cadastradas." if janelas.empty? || valores.keys.sort != janelas.sort
    raise ArgumentError, "A soma das cotas deve ser igual à cota diária." unless valores.values.sum == total

    Sorteio.transaction do
      sorteio = Sorteio.find_or_create_by!(data: data) { |novo| novo.status = "aberto" }
      sorteio.with_lock do
        raise ArgumentError, "As cotas só podem ser alteradas para sorteios abertos." unless sorteio.status == "aberto"
        sorteio.update!(cotas: sorteio.cotas.merge(restaurante.id.to_s => valores))
      end
      sorteio
    end
  rescue Date::Error
    raise ArgumentError, "Informe uma data válida."
  end

  def self.inteiro(valor)
    raise ArgumentError, "As cotas devem ser números inteiros não negativos." unless /\A\d+\z/.match?(valor.to_s)
    Integer(valor.to_s, 10)
  end
  private_class_method :inteiro
end
