ActiveRecord::Schema[7.1].define(version: 2026_10_27_120010) do
  create_table "acessos", force: :cascade do |t|
    t.string "usuario_matricula", null: false
    t.integer "catraca_id", null: false
    t.integer "turno_id", null: false
    t.integer "inscricao_fastpass_id"
    t.datetime "data_hora", null: false
    t.string "status", null: false
    t.datetime "passagem_em"
    t.decimal "valor_debitado", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["catraca_id"], name: "index_acessos_on_catraca_id"
    t.index ["inscricao_fastpass_id"], name: "index_acessos_on_inscricao_fastpass_id"
    t.index ["turno_id"], name: "index_acessos_on_turno_id"
    t.index ["usuario_matricula"], name: "index_acessos_on_usuario_matricula"
  end

  create_table "cardapios", force: :cascade do |t|
    t.integer "turno_id", null: false
    t.date "data", null: false
    t.string "opcao_padrao"
    t.string "opcao_ovolactovegetariana"
    t.string "opcao_vegetariana_estrita"
    t.index ["turno_id"], name: "index_cardapios_on_turno_id"
  end

  create_table "cardapios_restaurantes", id: false, force: :cascade do |t|
    t.integer "cardapio_id", null: false
    t.integer "restaurante_id", null: false
    t.index ["cardapio_id", "restaurante_id"], name: "index_cardapios_restaurantes_on_cardapio_id_and_restaurante_id", unique: true
    t.index ["restaurante_id"], name: "index_cardapios_restaurantes_on_restaurante_id"
  end

  create_table "catracas", force: :cascade do |t|
    t.integer "restaurante_id", null: false
    t.integer "piso", null: false
    t.string "modo_acesso", null: false
    t.index ["restaurante_id"], name: "index_catracas_on_restaurante_id"
  end

  create_table "inscricoes_fastpass", force: :cascade do |t|
    t.string "usuario_matricula", null: false
    t.integer "sorteio_id", null: false
    t.integer "time_frame_id", null: false
    t.string "resultado"
    t.string "status_notificacao", null: false
    t.datetime "notificada_em"
    t.index ["sorteio_id"], name: "index_inscricoes_fastpass_on_sorteio_id"
    t.index ["time_frame_id"], name: "index_inscricoes_fastpass_on_time_frame_id"
    t.index ["usuario_matricula"], name: "index_inscricoes_fastpass_on_usuario_matricula"
  end

  create_table "recargas", force: :cascade do |t|
    t.string "usuario_matricula", null: false
    t.datetime "data_hora", null: false
    t.decimal "valor", precision: 10, scale: 2, null: false
    t.string "metodo", null: false
    t.string "status", null: false
    t.index ["usuario_matricula"], name: "index_recargas_on_usuario_matricula"
  end

  create_table "restaurantes", force: :cascade do |t|
    t.string "nome", null: false
  end

  create_table "sorteios", force: :cascade do |t|
    t.date "data", null: false
    t.string "status", null: false
  end

  create_table "time_frames", force: :cascade do |t|
    t.integer "turno_id", null: false
    t.time "inicio", null: false
    t.time "fim", null: false
    t.index ["turno_id"], name: "index_time_frames_on_turno_id"
  end

  create_table "turnos", force: :cascade do |t|
    t.string "nome", null: false
    t.time "inicio", null: false
    t.time "fim", null: false
    t.decimal "preco", precision: 10, scale: 2, null: false
  end

  create_table "usuarios", primary_key: "matricula", id: :string, force: :cascade do |t|
    t.string "nome", null: false
    t.string "senha_hash", null: false
    t.integer "turno_id"
    t.integer "restaurante_id"
    t.string "perfil", null: false
    t.decimal "saldo", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["restaurante_id"], name: "index_usuarios_on_restaurante_id"
    t.index ["turno_id"], name: "index_usuarios_on_turno_id"
  end

  add_foreign_key "acessos", "catracas"
  add_foreign_key "acessos", "inscricoes_fastpass", column: "inscricao_fastpass_id"
  add_foreign_key "acessos", "turnos"
  add_foreign_key "acessos", "usuarios", column: "usuario_matricula", primary_key: "matricula"
  add_foreign_key "cardapios", "turnos"
  add_foreign_key "cardapios_restaurantes", "cardapios"
  add_foreign_key "cardapios_restaurantes", "restaurantes"
  add_foreign_key "catracas", "restaurantes"
  add_foreign_key "inscricoes_fastpass", "sorteios"
  add_foreign_key "inscricoes_fastpass", "time_frames"
  add_foreign_key "inscricoes_fastpass", "usuarios", column: "usuario_matricula", primary_key: "matricula"
  add_foreign_key "recargas", "usuarios", column: "usuario_matricula", primary_key: "matricula"
  add_foreign_key "time_frames", "turnos"
  add_foreign_key "usuarios", "restaurantes"
  add_foreign_key "usuarios", "turnos"
end
