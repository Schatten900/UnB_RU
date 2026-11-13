class AddCatracaToInscricoesFastpass < ActiveRecord::Migration[7.0]
  def change
    add_reference :inscricoes_fastpass,
                  :catraca,
                  null: true,
                  foreign_key: true,
                  index: true
  end
end
# AI: ChatGPT web
# Prompt: Modified by prompt on fixing fastpass
