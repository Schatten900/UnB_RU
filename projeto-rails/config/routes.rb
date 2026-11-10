Rails.application.routes.draw do
  # Health check do Rails
  get "up" => "rails/health#show", as: :rails_health_check
  get "terminal_validacao", to: "terminal_validacao#index", as: :terminal_validacao
  get "vagas_fastpass", to: redirect(path: "/admin/vagas_fastpass"), as: :vagas_fastpass
  get "extrato_refeicoes", to: "extrato_refeicoes#index", as: :extrato_refeicoes

  # Rotas de Autenticação
  root "autenticacao#new"
  get 'login', to: 'autenticacao#new', as: :login
  post 'login', to: 'autenticacao#create'
  delete 'logout', to: 'autenticacao#destroy', as: :logout

  # Ponto de configuração e Cadastro web
  get 'cadastro', to: 'cadastros#new', as: :new_cadastro
  get 'ponto_configuracao', to: 'ponto_configuracao#new', as: :ponto_configuracao
  post 'ponto_configuracao', to: 'ponto_configuracao#create'

  # Páginas principais e operacionais do estudante
  get "inicio", to: "cardapio#index", as: :inicio
  get 'recarga', to: 'recargas#index', as: :recarga
  get 'turnos', to: redirect(path: "/admin/turnos"), as: :turnos
  get 'relatorio_global', to: redirect(path: "/admin/relatorio_global"), as: :relatorio_global
  get 'fast_pass', to: 'fast_passes#index', as: :fast_pass

  # APIs (Endpoints que respondem em JSON consumidos via fetch)
  get "historico_local", to: "historico_local#index", as: :historico_local
  get "historico_local/exportar", to: "historico_local#exportar", as: :exportar_historico_local
  get "admin", to: redirect("/admin/restaurantes"), as: :admin_root
  scope path: "admin", as: "admin" do
    get "vagas_fastpass", to: "vagas_fastpass#index", as: :vagas_fastpass
    get "relatorio_global", to: "relatorios#global", as: :relatorio_global
  end

  namespace :admin do
    resources :turnos, only: [:index, :create, :update]
    resources :restaurantes, only: [:index, :create, :update, :destroy]
    resources :catracas, only: [:create, :update, :destroy]
  end
  
  namespace :api do
    resources :cadastros, only: [:create]
    
    resources :recargas, only: [:create] do
      member do
        post :confirmar # Mapeia explicitamente para /api/recargas/:id/confirmar
      end
    end

    resources :turnos, only: [:index, :show, :create, :update]
    
    get 'relatorios/global_operations', to: 'relatorios#global_operations'
    get 'relatorios/operacoes', to: 'relatorios#global_operations' # Alias unificado para atender as duas branches
  end
end

# DO NOT REMOVE THIS AI USE DISCLOSURE SECTION, IF YOU USE AI, ADD INTO IT! 
# AI: Deepseek and Gemini
# Strategy and prompt: Affected by several other prompts already documented here
