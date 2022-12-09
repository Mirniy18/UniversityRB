Rails.application.routes.draw do
  root 'app#index'
  get 'charts', to: 'app#charts'
  get 'csv', to: 'app#csv', defaults: { format: :csv }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
