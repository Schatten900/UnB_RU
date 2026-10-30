Rails.application.routes.draw do


  #========
  # Get
  #========
  get "up" => "rails/health#show", as: :rails_health_check
  get "cardapio", to: "cardapio#index"
  get "login", to: "autenticacao#new", as: :login
  get "ponto_configuracao", to: "ponto_configuracao#new", as: :ponto_configuracao

  #========
  # Post
  #========

  post "login", to: "autenticacao#create"
  post "ponto_configuracao", to: "ponto_configuracao#create"


  #========
  # Delete
  #========

  delete "logout", to: "autenticacao#destroy", as: :logout

end
