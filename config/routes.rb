# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :redmine_holidays, :only => :index
get '/holidays' => 'holidays#index', :as => :holidays
put '/holidays/update_extra_days' => 'holidays#update_extra_days', :as => :update_extra_days_holidays
post '/holidays/day_stats' => 'holidays#day_stats', :as => :day_stats

