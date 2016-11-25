Rails.application.routes.draw do

  devise_for :users

  authenticated :user  do
    root to: 'correspondence#index', as: :authenticated_root
  end

  resources :correspondence do
    resources :assignments
  end

  get '/search' => 'correspondence#search'

  root to: redirect('/users/sign_in')
end
