
Rails.application.routes.draw do
  namespace :api do

    # Cadastro
    post 'cadastro',
      to: 'cadastros#create'

    # Recargas
    resources :recargas, only: [:create] do
      member do
        post :confirmar
      end
    end

    # Relatório global
    get 'relatorios/operacoes',
      to: 'relatorios#global_operations'

    # Turnos e intervalos
    resources :turnos,
      only: [:index, :show, :create, :update]

  end
end
