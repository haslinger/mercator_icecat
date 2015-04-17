Mercator::Application.routes.draw do
  namespace :admin do
    resources :metadata
  end

  namespace :productmanager do
    get 'price_manager/import_icecat/:id' => 'price_manager#import_icecat'
  end
end
