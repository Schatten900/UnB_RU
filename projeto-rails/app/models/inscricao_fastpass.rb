#models/inscricao_fastpass.rb
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
  belongs_to :catraca, optional: true #Added by chatGPT when dealing with fastpasses 500 bug

	validates :resultado, inclusion: { in: RESULTADOS }, allow_nil: true

  attribute :status_notificacao, :string, default: "pendente"

  validates :time_frame, presence: { message: "precisa ser escolhido" }
  validate :usuario_deve_ser_estudante
  validate :inscricao_unica_por_turno

  private

  def usuario_deve_ser_estudante
    return if usuario.nil? || usuario.perfil == "estudante"

    errors.add(:usuario, "deve ser estudante")
  end

  def inscricao_unica_por_turno
    return if usuario.nil? || sorteio.nil? || time_frame.nil?

    existentes = self.class.joins(:time_frame)
                          .where(usuario_matricula: usuario_matricula, sorteio_id: sorteio_id)
                          .where(time_frames: { turno_id: time_frame.turno_id })
    existentes = existentes.where.not(id: id) if persisted?

    if existentes.exists?
      errors.add(:time_frame, "só permite uma inscrição por turno de refeição no mesmo sorteio")
    end
  end
end
