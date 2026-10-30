class PontoConfiguracaoService

    def self.call(restaurante_id:)
        return if restaurante_id.blank?

        Restaurante.find_by(id: restaurante_id)
    end

end
