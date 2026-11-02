
class Turno < ApplicationRecord
  has_many :time_frames,
    dependent: :destroy

  has_many :acessos

  validates :nome, presence: true
  validates :inicio, presence: true
  validates :fim, presence: true
  validates :preco,
    numericality: { greater_than_or_equal_to: 0 }

  validate :fim_depois_do_inicio

  private

  def fim_depois_do_inicio
    return unless inicio && fim

    if fim <= inicio
      errors.add(:fim, "deve ser posterior ao início")
    end
  end
end
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
