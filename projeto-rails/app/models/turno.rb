class Turno < ApplicationRecord
  has_many :time_frames,
    dependent: :destroy

  has_many :acessos
  has_many :cardapios
  has_many :usuarios

  validates :nome, presence: true
  validates :inicio, presence: true
  validates :fim, presence: true
  validates :preco,
    numericality: { greater_than_or_equal_to: 0 }

  validate :fim_depois_do_inicio

  private

  def fim_depois_do_inicio
    return unless inicio && fim

    if fim == inicio
      errors.add(:fim, "deve ser diferente do início")
    end
  end
end
