Dradis::Plugins::Calculators::AivssSsvc::Engine.routes.draw do
  get '/calculators/aivss_ssvc' => 'base#index'

  resources :projects, only: [] do
    resources :issues, only: [] do
      member do
        get   'aivss_ssvc' => 'issues#edit'
        patch 'aivss_ssvc' => 'issues#update'
      end
    end
  end
end
