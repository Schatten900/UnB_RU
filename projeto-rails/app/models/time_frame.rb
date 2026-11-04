class TimeFrame < ApplicationRecord
  belongs_to :turno

  validates :inicio, presence: true
  validates :fim, presence: true

  validate :fim_depois_do_inicio

  private

  def fim_depois_do_inicio
    return unless inicio && fim

    if fim <= inicio
      errors.add(:fim, "deve ser posterior ao início")
    end
  end
end
