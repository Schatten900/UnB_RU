Rails.application.routes.draw do
  # Rotas de Autenticação (apontando para AutenticacaoController)
  get 'login', to: 'autenticacao#new', as: :login
  post 'login', to: 'autenticacao#create'
  delete 'logout', to: 'autenticacao#destroy', as: :logout

  # Cadastro
  get 'cadastro', to: 'cadastros#new', as: :new_cadastro

  # Porta do estudante e recarga
  root 'home#index' 
  get 'recarga', to: 'recargas#index', as: :recarga

    # Relatorios global e turnos
  get 'turnos', to: 'turnos#index', as: :turnos
  get 'relatorio_global', to: 'relatorios#global', as: :relatorio_global

  #Fast passes
  get 'fast_pass', to: 'fast_passes#index', as: :fast_pass

  # APIs (Endpoints que respondem em JSON consumidos via fetch)
  namespace :api do
    resources :cadastros, only: [:create]
    
    resources :recargas, only: [:create] do
      member do
        post :confirm # Mapeia para /api/recargas/:id/confirm
      end
    end

    resources :turnos, only: [:index, :show, :create, :update]
    
    get 'relatorios/global_operations', to: 'relatorios#global_operations'
  end
end

# DO NOT REMOVE THIS AI USE DISCLOSURE SECTION, IF YOU USE AI, ADD INTO IT! 
# AI: Deepseek and Gemini
# Strategy and prompt: Affected by several other prompts already documented here
