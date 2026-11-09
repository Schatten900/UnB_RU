
Rails.application.routes.draw do
  root "cardapio#index"
  get "up" => "rails/health#show", as: :rails_health_check
  get "login", to: "autenticacao#new", as: :login
  get "ponto_configuracao", to: "ponto_configuracao#new", as: :ponto_configuracao
  post "login", to: "autenticacao#create"
  post "ponto_configuracao", to: "ponto_configuracao#create"
  delete "logout", to: "autenticacao#destroy", as: :logout

  get "historico_local", to: "historico_local#index", as: :historico_local
  get "historico_local/exportar", to: "historico_local#exportar", as: :exportar_historico_local
  namespace :admin do
    resources :turnos, only: [:index, :create, :update]
    resources :restaurantes, only: [:index, :create, :update, :destroy]
    resources :catracas, only: [:create, :update, :destroy]
  end
  
  namespace :api do
    post "cadastro", to: "cadastros#create"
    resources :recargas, only: [:create] do
      member do
        post :confirmar
      end
    end

    get "relatorios/operacoes", to: "relatorios#global_operations"
    # Turnos e intervalos
    resources :turnos,
      only: [:index, :show, :create, :update]
  end
end
