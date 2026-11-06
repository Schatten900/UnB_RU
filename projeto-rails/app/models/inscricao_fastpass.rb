class InscricaoFastpass < ApplicationRecord
	self.table_name = "inscricoes_fastpass"

	RESULTADO_GANHOU = "ganhou".freeze
	RESULTADO_NAO_GANHOU = "nao_ganhou".freeze
	RESULTADOS = [RESULTADO_GANHOU, RESULTADO_NAO_GANHOU].freeze

	belongs_to :sorteio
	belongs_to :time_frame
	belongs_to :usuario,
		foreign_key: :usuario_matricula,
		primary_key: :matricula

	validates :resultado, inclusion: { in: RESULTADOS }, allow_nil: true
end
