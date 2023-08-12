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

  # User routes
  post '/login', to: 'sessions#create'

  put '/update_user', to: 'users#update_user'

  delete "/delete_user" , to: "users#delete_user"

  get '/profile', to: 'users#profile'

  get '/my_posts', to: 'users#my_posts'

  put '/follow_user', to: 'users#follow_user'

  get '/show_author', to: 'users#show_author'

  put "/add_like", to: "users#add_like"

  put "/add_comment", to: "users#add_comment"

  get '/recommended_posts', to: "users#recommended_posts"

  get '/allTopics', to: "users#allTopics"

  get '/similar_author_posts', to: "users#similar_author_posts"

  put '/subscribe_without_payment' , to: "users#subscribe_without_payment"

  put "/show", to: "users#show"

  #revision history
  get "/show_revision_history" , to: "users#show_revision_history"

  #Drafts
  post "/create_draft" , to: "users#create_draft"

  put "/update_draft" , to: "users#update_draft"

  get "/my_drafts" , to: "users#my_drafts"

  delete "/delete_draft" , to: "users#delete_draft"

  #saved articles
  get '/saved_articles', to: 'users#saved_articles'

  post '/save_article_for_later', to: 'users#save_article_for_later'

  #lists
  post '/create_article_in_list', to: 'users#create_article_in_list'

  get '/view_list', to: 'users#view_list'

  get '/share_list', to: 'users#share_list'

  #payment routes

  post '/subscribe', to: "payments#subscribe"

  post '/payment_callback', to: "payments#payment_callback"

  get '/payments_page', to: "payments#payments_page"

end
