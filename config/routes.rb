Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")

  #articles routes

  root "articles#home"

  post "articles/create", to: "articles#create"

  put "articles/update", to: "articles#update"

  delete "articles/delete", to: "articles#delete"

  get "articles/filter", to: "articles#filter"

  get "articles/search", to: "articles#search"

  get "articles/sort", to: "articles#sort"

  get "articles/all", to: "articles#all"

  get "articles/top_posts", to: "articles#top_posts"

  #Users routes

  resources :users, only: [:create]

  # User Login
  post '/login', to: 'sessions#create'

  # Profile
  get '/profile', to: 'users#profile'

  # My Posts
  get '/my_posts', to: 'users#my_posts'

  put '/follow_user', to: 'users#follow_user'

  get '/show_author', to: 'users#show_author'

  put "/add_like", to: "users#add_like"

  put "/add_comment", to: "users#add_comment"

  get '/recommended_posts', to: "users#recommended_posts"

  get '/allTopics', to: "users#allTopics"

  get '/similar_author_posts', to: "users#similar_author_posts"

  put '/subscribe', to: "users#subscribe"

  put "/show", to: "users#show"
end
