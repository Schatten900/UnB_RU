#models/time_frame.rb
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
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb
