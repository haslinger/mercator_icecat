Mercator::Application.routes.draw do
    namespace :admin do
      resources :metadata
    end
end
