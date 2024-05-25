Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root 'blogs#select_csv'

  resources :blogs, only: [:index] do
    collection do
      get  'select_csv'
      post 'import_csv'
    end
  end
end
