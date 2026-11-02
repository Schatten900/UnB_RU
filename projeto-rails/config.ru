# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
Rails.application.load_server


Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # API 
  namespace :api do

    # Credits
    resources :credits, only: [:create] do
      member do
        post :confirm
      end
    end

    # Global report
    get 'reports/global_operations',
      to: 'reports#global_operations'

    # Shifts
    resources :shifts,
      only: [:index, :show, :create, :update]

    # Student registration
    post 'register',
      to: 'registrations#create'

  end

end
