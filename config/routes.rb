Dradis::Plugins::Calculators::AIVSSSSVC::Engine.routes.draw do
  get '/calculators/aivss_ssvc' => 'base#index'
  post '/calculators/aivss_ssvc/fields' => 'base#fields', as: :calculators_aivss_ssvc_fields

  resources :projects, only: [] do
    resources :issues, only: [] do
      member do
        get 'aivss_ssvc' => 'issues#edit'
        patch 'aivss_ssvc' => 'issues#update'
      end
    end
  end
end
