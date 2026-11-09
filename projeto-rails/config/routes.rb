Rails.application.routes.draw do
  # Health check do Rails
  get "up" => "rails/health#show", as: :rails_health_check

  # Rotas de Autenticação
  get 'login', to: 'autenticacao#new', as: :login
  post 'login', to: 'autenticacao#create'
  delete 'logout', to: 'autenticacao#destroy', as: :logout

  # Ponto de configuração e Cadastro web
  get 'cadastro', to: 'cadastros#new', as: :new_cadastro
  get 'ponto_configuracao', to: 'ponto_configuracao#new', as: :ponto_configuracao
  post 'ponto_configuracao', to: 'ponto_configuracao#create'

  # Páginas principais e operacionais do estudante
  root 'cardapio#index' # Ou 'cardapio#index' conforme preferência da sprint-2, mantido home#index para atender o HomeController criado
  get 'recarga', to: 'recargas#index', as: :recarga
  get 'turnos', to: 'turnos#index', as: :turnos
  get 'relatorio_global', to: 'relatorios#global', as: :relatorio_global
  get 'fast_pass', to: 'fast_passes#index', as: :fast_pass

  # APIs (Endpoints que respondem em JSON consumidos via fetch)
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
