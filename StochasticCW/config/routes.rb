Rails.application.routes.draw do
  root 'the#index'
  get 'charts', to: 'the#charts'
  get 'csv', to: 'the#csv', defaults: { format: :csv }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
