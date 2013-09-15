Dummy::Application.routes.draw do
  get ':controller(/:action(/:id(.:format)))'
  resources :albums
end
